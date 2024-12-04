# Releases

### 0.0.18 / 2024.12.04

- Resolved an issue where all open connections between the proxy and worker were
  not severed immediately when a worker became unreachable, causing HTTP
  requests to hang.
- Resolved an issue where isolate logs exported through the OpenTelemetry
  pipeline were not always completely flushed (e.g. when an isolate crashes).
- Multiple isolates of the same deployment invoked with different
  `x-deno-isolate-instance-id` now correctly share web caches.
- It is no longer a requirement that all entries in a deployment tarball are
  prefixed with `./`.
- The `ddng deploy` command now triggers a hostmap cache flush in the proxy,
  reducing the delay for a new deployment to an existing domain to become
  visible.
- Added support for configuring the OpenTelemetry service name and resource
  attributes for individual deployments. When using the `ddng` script to make
  deployments, these can be specified using the `--otel-service-name` and
  `--otel-resource-attribute` flags.
- Metrics exported by the proxy and controller now use the prefix
  `deno_cluster_` for easy identification.

### 0.0.17 / 2024.11.20

- The terraform modules now output the Helm configuration to stdout, in addition
  to generating a ready-to-use `values.yaml` file.
- The controller now exposes various metrics, such as the number of active
  isolate workers, through the OpenTelemetry pipeline.
- Improved error transparency when an HTTP request fails to be processed by an
  isolate. The underlying cause is now provided via the `x-deno-error` response
  header.
- The container registry was switched to Github Container Registry (ghcr.io).
