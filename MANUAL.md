# Manual

## `ddng` Command Line Tool

### Making a Deployment

The command line tool available at `./tools/ddng` is used to package and deploy
applications. The application has few external dependencies — [`deno`][deno]
must be installed, as well as the [AWS cli][aws].

### Usage

To create a deployment, run the following command:

```bash
./tools/ddng deploy --domain hello.mycluster.deno-cluster.net --source-dir /path/to/source/dir --s3-bucket s3://my-code-bucket
```

The following options are available:

| short | long                   | value       | description                                                                       |
| ----- | ---------------------- | ----------- | --------------------------------------------------------------------------------- |
| `-d`  | `--domain`             | domain      | Deployment domain (e.g., hello.mycluster.deno-cluster.net)                        |
| `-s`  | `--source-dir`         | dir         | Source directory (default: current directory)                                     |
| `-e`  | `--entry-point`        | file        | Specify entry point (default: auto detect)                                        |
|       | `--env`                | KEY=VALUE   | Set environment variables using KEY=VALUE format, can be specified multiple times |
|       | `--s3-bucket`          | bucket      | Specify S3 bucket (required if using AWS)                                         |
|       | `--az-storage-account` | account     | Azure storage account (required if using Azure)                                   |
|       | `--skip-optimize`      |             | Skip the optimization step                                                        |

### With AWS S3

The AWS needs to be configured to use the S3 bucket that Deno Deploy Next Gen
uses on the backend. In case this isn't already the case, follow [AWS's
instructions][aws-configure].

### With Minio

If you're using Minio instead of AWS S3 you will also need to [configure the AWS
cli][aws-configure] — Since Minio is compatible with S3 the ddng tool uses the
AWS cli under the hood to communicate with Minio. If you're using the default
values, export the following environment variables.

```bash
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
export AWS_REGION=<your region>
```

If you have customized those values, make sure they match what's configured on
the server. The `AWS_REGION` value must match the value configured on the Helm
chart.

## Cluster Configuration

### Controller

The controller is responsible of maintaining a pool of pods ready to be assigned
to a deployment, and assign to deployments to those pods when needed. It's the
primary scaling controller of the system.

#### Configuration Options

The following are set as environment variables on the `controller` deployment.
To change them, refer to the [example values file for Helm][example-values]

* `ISOLATE_WORKER_CPU_REQUEST` (default `15m`): How much CPU requests to set on
  each isolate-worker pod. This setting is applied to assigned and free pods as
  well, which means it affects how many pods can fit on a node even without any
  load on the system.
* `ISOLATE_WORKER_MIN_CPU_PER_NODE` (default `1500m`): How much CPU to schedule
  on a node. In combination with `ISOLATE_WORKER_CPU_REQUEST`, this tells the
  controller how many free pods to schedule on each node.

> [!IMPORTANT]
> It's important to highlight the relationship between
> `ISOLATE_WORKER_CPU_REQUEST` and `ISOLATE_WORKER_MIN_CPU_PER_NODE` — With the
> default values, the controller will schedule 100 isolate-workers on each node.
> (scheduling `1500m` cpu on each node, divided by `15m` for each worker). By
> contrast, setting both to `1000m` will force the controller to schedule only
> a single isolate-worker per node.

* `MIN_ISOLATE_WORKER_REPLICAS` (default `4`): The minimum number of ***total***
  isolate-workers to schedule.
* `MAX_ISOLATE_WORKER_REPLICAS` (default `10`): The maximum number of ***total***
  isolate-workers to schedule
* `ISOLATE_TARGET_FREE_POOL_RATIO` (default `0.5`): The minimum ratio of free
  pods over the total number of isolate-workers. This ensures that the number of
  free pods is always _at least_ $(free+assigned)*ratio$.
* `NODE_METRICS_SELECTOR`: When set, the controller will apply this label
  selector to determine which nodes to scrape metrics from. It is assumed that
  isolate-workers will run only on nodes matching this label selector.

#### Advanced Configration Options

> [!WARNING]
> The following are advanced configuration options and can seriously impact how
> the system behaves. If you don't know what you're doing, leave the default
> values.

* `CLUSTER_CPU_PCT_TARGET` (default `0.6`) Target _average_ cpu utilization
  across the cluster.
* `CLUSTER_MEMORY_PCT_TARGET` (default `0.6`) Target _average_ memory
  utilization across the cluster.

The controller will **up** when either one of those is reached, and scale back
**down** when utilization is under both of those.

### OpenTelemetry

Logs and traces from isolates are exported via OpenTelemetry to an OpenTelemetry
Collector deployed in the cluster. By default, these aren't exported anywhere.
The Helm chart supports configuration options to send these signals to your
prefered destination. We currently support anonymous OTLP over gRPC and OTLP
over HTTP with basic auth. Add the following to your values file:

```yaml
# OTLP/gRPC
otlp:
  endpoint: http://your.collector:4317

# OTLP/HTTP
otlphttp:
  endpoint: https://your.collector:4318
  # optional:
  auth:
    authenticator: "basicauth/otlp" # must be exactly
    username: <user>
    password: <pass>
```

> ![NOTE]
> The Helm chart requires the OpenTelemetry Operator as a dependency. To have
> full control over logs and traces, including relabelling and sampling, we
> recommend deploying your own collector instance inside the cluster and use
> that as your export endpoint in the Helm chart configuration.

## Advanced Features

### Targeting A Specific Isolate

Normally, requests are load balanced across V8 isolates. In order to target a
specific isolate, you can add the `x-deno-isolate-instance-id` header or the
`deno_isolate_instance_id` query string parameter to your request.

When an isolate ID is specified, all requests with the same isolate ID are
_guaranteed_ to be handled by the same isolate. This isolate is dedicated to
this ID and it doesn't handle any requests with a different isolate id or
requests that don't have an isolate ID at all.

These "dedicated" isolates with an ID are subject to normal time-out behavior.

You can find an example [here][instance-id].

[deno]: https://deno.com
[aws]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[aws-configure]: https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-configure.html
[instance-id]: ./examples/instance-id/README.md
[example-values]: ./helm/deno-cluster/example.values.yaml
