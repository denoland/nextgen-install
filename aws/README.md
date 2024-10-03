# Deno Cluster AWS module

## Prerequisites

1. Make sure you have to following command line tools installed:
   - [`aws`][aws] (AWS CLI)
   - [`kubectl`][kubectl] (Kubernetes command line tool)
   - [`helm`][helm] (Helm CLI)
2. Log in to AWS with `aws configure` or `aws sso login`.

## Provision AWS resources using terraform

Fill out the `locals` block with information specific to your environment.

You'll need designate domain name like
`mycluster.deno-cluster.net` or `dev.mycompany.com`, which you can delegate
(using an NS record) to AWS hosted zone, to attach to the cluster.

```terraform
locals {
  domain_name = "mycluster.deno-cluster.net"  # <— The DNS zone that terraform will create in AWS.
  eks_cluster_name = "deno-cluster-01"        # <— The name of the EKS cluster.
  eks_cluster_region   = "us-west-2"          # <— The AWS region to deploy to.
}
```

Finally, run `terraform init` to initialize the Terraform configuration and run
`terraform apply` to create the resources.

:warning: `terraform apply` will not complete until a certificate for the domain is
issued by AWS and validated. Certificate validation requires DNS delegation to
AWS, which is covered in the next section. Please proceed to [DNS Configuration](#dns-configuration)
while `terraform apply` is running.

Take note of the outputs of the plan, you'll need these values later to
configure your Deno Cluster installation.

Note: `secret_access_key` output is sensitive and should be treated as a
secret. run `terraform output secret_access_key` to get the value.

## DNS Configuration

In your domain registrar or DNS provider, delegate the DNS zone for your cluster
domain name (e.g. `mycluster.deno-cluster.net`) to AWS. Use the following command
to get the NS records for the DNS zone (set `DOMAIN_NAME` to your domain name):

```bash
export DENO_CLUSTER_DOMAIN_NAME=mycluster.deno-cluster.net
aws route53 list-hosted-zones --query "HostedZones[?Name=='$DENO_CLUSTER_DOMAIN_NAME.'].Id" --output text | xargs -I {} aws route53 get-hosted-zone --id {} --query "DelegationSet.NameServers" --output json | jq -r '.[]'

```

The name servers will look similar to this:

```
ns-1.awsdns-05.org
ns-2.awsdns-50.net
ns-3.awsdns-22.com
ns-4.awsdns-08.co.uk
```

To delegate your cluster domain name to AWS DNS, you would add the following
records to your existing DNS provider:

```
mycluster.deno-cluster.net.  IN  NS  ns-1.awsdns-05.org.
mycluster.deno-cluster.net.  IN  NS  ns-2.awsdns-50.net.
mycluster.deno-cluster.net.  IN  NS  ns-3.awsdns-22.com.
mycluster.deno-cluster.net.  IN  NS  ns-4.awsdns-08.co.uk.
```

## Connect To The Cluster

Update DENO_CLUSTER_NAME and DENO_CLUSTER_REGION with your values and run:

```bash
export DENO_CLUSTER_NAME=deno-cluster-01
export DENO_CLUSTER_REGION=us-west-2
aws eks update-kubeconfig --name $DENO_CLUSTER_NAME --region $DENO_CLUSTER_REGION
```

## Install Dependencies In The Cluster

The Deno Cluster Helm chart depends on `karpenter` and
`opentelemetry-operator`. You can install them with the following commands:

```bash
kubectl apply -f ./karpenter
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo add jetstack https://charts.jetstack.io --force-update

helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system \
  --create-namespace \
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-k8s" \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true
```

Note: this script is included for convenience at `helm/deps.sh`.

# Install The Deno Cluster Helm Chart

Update the values in the example `values.yaml` provided with the values provided
in the Terraform output. They're highlighted in the example below.

```yaml
provider: aws
region: us-west-2 # CHANGE ME
hostname: mycluster.deno-cluster.net # CHANGE ME

aws:
  subnet: deno-cluster-01-subnet1 # CHANGE ME
  nlb: deno-cluster-01-nlb # CHANGE ME

blob:
  s3:
    access_key: 0123456789ABCDEFGHIJ # CHANGE ME
    secret_key: ------------------------------ # CHANGE ME
    code_storage_bucket: deno-cluster-01-code-storage-f65ef9c1 # CHANGE ME
    cache_storage_bucket: deno-cluster-01-lsc-storage-f65ef9c1 # CHANGE ME

# Uncomment the following block to send logs to an OTLP endpoint.
# otlp:
#   endpoint: https://otlp-gateway-prod-us-east-0.grafana.net/otlp
#   auth:
#     authenticator: basicauth/otlp
#     username: "103456"
#     password: "ghc_xxx"

controller:
  serviceaccount_annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::0123456789012:role/eks-service-account-f65ef9c1 # CHANGE ME
  env:
    - name: NODE_METRICS_SELECTOR
      value: karpenter.sh/provisioner-name=default

proxy:
  serviceaccount_annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::0123456789012:role/eks-service-account-f65ef9c1 # CHANGE ME
```

Then, install the `deno-cluster` Helm chart.

:warning: The Helm chart must be installed into the `default` namespace.

```bash
helm install --namespace=default -f ./values.yaml deno-cluster ../helm/deno-cluster
```

# Create a Deployment

In the `tools` directory, we've included a command line utility that creates new
deployments. You can use it as follows to deploy your first "hello world" app.

Note: substitute `<cluster_domain>` for the value you specified `, e.g. `mycluster.deno-cluster.net`.
Note: substitute `<code-storage-bucket>`for the value from the terraform output, e.g.`deno-cluster-01-code-storage-f65ef9c1`.

```bash
../tools/ddng deploy \
  -s ../examples/hello \
  -d hello.<cluster_domain> \
  --s3-bucket <code-storage-bucket>
```

[aws]: https://aws.amazon.com/cli/
[helm]: https://helm.sh/docs/intro/install/
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
