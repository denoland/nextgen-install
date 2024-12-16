# Releases

### 0.0.20 / 2024.12.16

- Resolved an issue where the controller would wait indefinitely for a worker
  that failed to start. The controller now marks a worker as failed if it does
  not start within 60 seconds.
- Failures during startup and uncaught exceptions are now logged through the
  OpenTelemetry pipeline as `boot_failure` and `uncaught_exception` events,
  respectively.

### 0.0.19 / 2024.12.11

- Resolved an issue where additional workers for a deployment would fail to
  start when the controller had been restarted or failed over between the
  creation of the initial worker and the subsequent scale-up event.
- Fixed typos in the Terraform script for Azure.
- Added native support for ARM64 architecture, expanding container image
  compatibility beyond x86_64 to include linux/arm64 platforms.

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
