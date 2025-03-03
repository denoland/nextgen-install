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
  domain_name          = "mycluster.deno-cluster.net" # <— The DNS zone that terraform will create in AWS.
  eks_cluster_name     = "deno-cluster-01"            # <— The name of the EKS cluster.
  eks_cluster_region   = "us-west-2"                  # <— The AWS region to deploy to.
}
```

Finally, run `terraform init` to initialize the Terraform configuration and run
`terraform apply` to create the resources.

Take note of the outputs of the plan, you'll need these values later to
configure your Deno Cluster installation.

The plan creates a file called `values.yaml` with the values necessary for the
installation of the Helm chart later. If you're running in CI and can't access
that file, the values are included in the plan's output and can be copied from
there.

**NOTE:** It's expected that the Terraform apply fail the first time. This is
due to two things: Interdependencies between Terraform providers, and a
dependency on DNS configuration. Move on to the next steps, you will be asked
to re-run Terraform, at which point it should pass successfully.

## DNS Configuration

In your domain registrar or DNS provider, delegate the DNS zone for your cluster
domain name (e.g. `mycluster.deno-cluster.net`) to AWS. Use the following command
to get the NS records for the DNS zone (set `DOMAIN_NAME` to your domain name):

```bash
terraform output
```

The name servers will look similar to this:

```
# ...
hosted_zone_nameservers = tolist([
  "ns-1441.awsdns-52.org",
  "ns-1909.awsdns-46.co.uk",
  "ns-429.awsdns-53.com",
  "ns-592.awsdns-10.net",
])
# ...
```

To delegate your cluster domain name to AWS DNS, you would add the following
records to your existing DNS provider:

```
mycluster.deno-cluster.net.  IN  NS  ns-1.awsdns-05.org.
mycluster.deno-cluster.net.  IN  NS  ns-2.awsdns-50.net.
mycluster.deno-cluster.net.  IN  NS  ns-3.awsdns-22.com.
mycluster.deno-cluster.net.  IN  NS  ns-4.awsdns-08.co.uk.
```

> [!NOTE]
> Once the Terraform plan has run to completion, the AWS will validate the
> certificate through the DNS records that were created by Terraform. You don't
> have to wait for it to be validated to continue, but you will need to make
> sure the validation completed before making a deployment. To do so, run the
> following command:
>
> ```bash
> aws acm wait certificate-validated --certificate-arn <arn>
> ```

## Connect To The Cluster

Update DENO_CLUSTER_NAME and DENO_CLUSTER_REGION with your values and run:

```bash
export DENO_CLUSTER_NAME=deno-cluster-01
export DENO_CLUSTER_REGION=us-west-2
aws eks update-kubeconfig --name $DENO_CLUSTER_NAME --region $DENO_CLUSTER_REGION
```

# Install The Deno Cluster Helm Chart

Terraform should have created a file called `values.yaml` in the working
directory, make sure it exists by running `terraform apply` again, then install
the chart with the following command:

```bash
helm install --namespace=default -f ./values.yaml deno-cluster ../helm/deno-cluster
```

> [!WARNING]
> The auto-generated `values.yaml` file sets `auth.allow_bypass: true`, which
> bypasses the authorization mechanism around isolate-workers, and allows them
> to reach internal APIs. We recommend you enable [Cluster API authorization][cluster-auth]
> to ensure that untrusted workloads cannot access the cluster's internal APIs.

## Install the `metrics-server`

Deno Cluster requires `metrics-server` to be available on the cluster, you can
install it with this command:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

# Create a Deployment

In the `tools` directory, we've included a command line utility that creates new
deployments. You can use it as follows to deploy your first "hello world" app.

Note: substitute `<cluster_domain>` for the value you specified, e.g. `mycluster.deno-cluster.net`.
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
[cluster-auth]: https://github.com/denoland/nextgen-install/wiki/Cluster-API-Auth
