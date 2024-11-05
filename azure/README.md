# Deno Cluster Azure module

## Prerequisites

1. Make sure you have to following command line tools installed:
   - [`az`][az] (Azure CLI)
   - [`kubectl`][kubectl] (Kubernetes command line tool)
   - [`helm`][helm] (Helm CLI)
   - [`cmctl`][cmctl] (cert-manager command line tool)
2. Log in to Azure with `az login`.

## Provision Azure resources using terraform

Open the `main.tf` file and fill out the information in the `provider` block.
You can obtain your Azure Subscription ID using the following shell command:

```bash
az account show --query id --output tsv
```

```terraform
provider "azurerm" {
  subscription_id = "68245e99-8e6b-43ff-931c-0a895801acad" # <- Fill in your Azure subscription ID here.
  environment     = "public"
  features {}
}
```

Next, fill out the `locals` block with information specific to your environment.

You'll need designate domain name with 3 or more labels like
`mycluster.deno-cluster.net` or `dev.mycompany.com`, which you can delegate
(using an NS record) to Azure DNS, to attach to the cluster.

:warning: The 3-or-more-labels requirement is due to a limitation of Microsoft
Azure. In the future we hope to find a workaround for this issue.

```terraform
locals {
  dns_zone = "deno-cluster.net"  # <— The DNS zone that terraform will create in Azure.
  dns_root = "mycluster"         # <— The leftmost label of your cluster domain name.
  name     = "deno-cluster-01"   # <— This name will be used to create a new resource group and name various resources.
  region   = "westus"            # <— The Azure region to deploy to.
}
```

Finally, run `terraform init` to initialize the Terraform configuration and run
`terraform apply` to create the resources.

Take note of the outputs of the plan, you'll need these values later to
configure your Deno Cluster installation.

## DNS Configuration

In your domain registrar or DNS provider, delegate the DNS zone for your cluster
domain name (e.g. `mycluster.deno-cluster.net`) to Azure. The name servers to
use are shown after running `terraform apply`; it would look like this:

```
dns_zone_ns_records = toset([
  "ns1-05.azure-dns.com.",
  "ns2-05.azure-dns.net.",
  "ns3-05.azure-dns.org.",
  "ns4-05.azure-dns.info.",
])
```

To delegate your cluster domain name to Azure DNS, you would add the following
records to your existing DNS provider:

```
mycluster.deno-cluster.net.  IN  NS  ns1-05.azure-dns.com.
mycluster.deno-cluster.net.  IN  NS  ns2-05.azure-dns.net.
mycluster.deno-cluster.net.  IN  NS  ns3-05.azure-dns.org.
mycluster.deno-cluster.net.  IN  NS  ns4-05.azure-dns.info.
```

## Connect To The Cluster

Follow the [instructions provided by Azure][aks_creds] to use the Azure CLI to
connect to your cluster.

```bash
# Resource group and cluster name should be printed in the `terraform apply` output
az aks get-credentials --resource-group <resource_group_name> --name <aks_cluster_name>
```

## Install Dependencies In The Cluster

The Deno Cluster Helm chart depends on `cert-manager` and
`opentelemetry-operator`. You can install both with the following commands:

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo add jetstack https://charts.jetstack.io --force-update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.3 \
  --set crds.enabled=true \
  --set-json 'podLabels={"azure.workload.identity/use": "true"}' \
  --set-json 'serviceAccount={"labels": {"azure.workload.identity/use": "true"}}' \
  --set enableCertificateOwnerRef=true \
  --set dns01RecursiveNameserversOnly=true

helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system \
  --create-namespace \
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-k8s" \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true
```

Note: this script is included for convenience at `helm/deps.sh`.

# Install The Deno Cluster Helm Chart

Terraform should have created a file called `values.yaml` in the working
directory, make sure it exists before installing the chart with the following
command:

:warning: The Helm chart must be installed into the `default` namespace.

```bash
helm install --namespace=default -f ./values.yaml deno-cluster ../helm/deno-cluster
```

# Provision TLS certificates

After installing the Helm chart, the cluster will automatically try to obtain a
TLS certificate from Let's Encrypt. This might take a few minutes.

To see the progress of the certificate provisioning progress, use the following
command:

```bash
cmctl status certificate public-tls-cert
```

When provisioning is complete, its output will look like this:

```
Name: public-tls-cert
Namespace: default
Created at: 2024-09-05T14:10:12-07:00
Conditions:
  Ready: True, Reason: Ready, Message: Certificate is up to date and has not expired
DNS Names:
- mycluster.deno-cluster.net
- *.mycluster.deno-cluster.net
Events:  <none>
Issuer:
  Name: letsencrypt-production
  Kind: ClusterIssuer
...
```

After the TLS certificate has been provisioned, restart the proxy to ensure it
uses the new certificate:

```bash
kubectl rollout restart deployment/proxy
```

# Create a Deployment

In the `tools` directory, we've included a command line utility that creates new
deployments. You can use it as follows to deploy your first "hello world" app.

Because we're using Minio as the object store, the deployment script is using
the AWS cli under the hood, so you'll need to set some environment variables as
per the example below. To get the external IP for Minio, run `kubectl get
service minio-external`.

Note: substitute `<cluster_domain>` for the value that were shown after running
`terraform apply`, e.g. `mycluster.deno-cluster.net`.

```bash
AWS_ACCESS_KEY_ID=minioadmin \
AWS_SECRET_ACCESS_KEY=minioadmin \
AWS_REGION=westus \
S3_ENDPOINT=http://<minio_external_ip>:9000 \
../tools/ddng deploy \
  -s ../examples/hello \
  -d hello.<cluster_domain> \
  --s3-bucket deployments
```

[aks_creds]: https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli#connect-to-the-cluster
[az]: https://learn.microsoft.com/en-us/cli/azure/
[cmctl]: https://cert-manager.io/docs/reference/cmctl/
[helm]: https://helm.sh/docs/intro/install/
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
