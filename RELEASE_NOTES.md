# Releases

### 0.0.25 / 2025.03.28

- Added support for multiple isolate worker pools
  - Pools are automatically provisioned using Karpenter, and isolated using
    Kubernetes node labels, taints, and tolerations.
  - Each pool has its own configuration including dedicated resources, scaling
    parameters, and node allocation. See [controller
    configuration](https://github.com/denoland/nextgen-install/wiki/Controller-Configuration)
    for details.
  - A deployment can specify a pool using the `pool` parameter in its
    [AppConfig].
  - The proxy now includes the pool name in the `Via` header.
- Unstable [Deno.Kv] APIs are now disabled.
- The `RUST_LOG` environment variable is now respected in all components.
- The trace ID is now returned in the HTTP response through the `x-deno-trace-id` header.
- Traces are now propagated all the way to user code.
- Fixed auto-detection of code bucket location in us-east-1.

### 0.0.24 / 2025.03.24

> [!IMPORTANT]
> **Before upgrading** please run `kubectl delete configmap root-seed-commitment`.
> This will force the `controller` component to regenerate the configmap, which
> is necessary to upgrade to version 0.0.24

- [experimental] Added support for multi-region replication of user code in the controller.
- The proxy now supports the PROXY protocol, allowing client IP to be preserved end-to-end.
- Isolate workers now export internal spans, this is particularly useful to debug the boot process.
- The proxy now uses a Horizontal Pod Autoscaler for improved scalability.
- New object API for interacting with the code bucket. See [Cluster Object API] for details.
- Updated the scaling heuristic to consider both CPU and memory utilization.
- Improved stability when isolate-workers shut down.
- The Deno version was upgraded to v2.2.x
- The deployment id no longer includes the `appconfig://` prefix.
- The controller now has a `/dump-workers` endpoint that returns information about isolate workers for debugging.

### 0.0.23 / 2025.02.28

- Introduced the [AppConfig] system, replacing the previous deployment mechanism
  that relied on `layers://` URLs, the `hostmap` directory, and the
  `x-deno-isolate-id` header.
- Several cluster APIs now require authentication. See [Cluster API Auth] for
  details.
- Implemented dynamic TLS certificate serving for custom domains in the proxy.
  See [Dynamic TLS Certificates] for details.
- Improved cache support. See [Cache] for details.
  - Implemented an automatic HTTP response cache.
  - Added cache sharing between deployments configurable via [AppConfig].
- Updated packaged deno binary:
  - Changed spans to use fractional milliseconds for timestamps instead of
    fractional seconds.
  - Added built-in HTTP server metrics:
    - `http.server.request.duration`
    - `http.server.active_requests`
    - `http.server.request.body.size`
    - `http.server.response.body.size`
- Added proxy metrics:
  - `http_requests_total`: Counter for HTTP requests with deployment ID and
    status attributes
  - `response_latency`: Histogram tracking HTTP response latency in milliseconds
  - `http_requests_cache_hit`: Counter tracking HTTP requests that hit the cache
  - `http_response_cache_writes`: Counter tracking HTTP responses written to cache
- Configured workers to use a separate `dnsmasq` DNS resolver for improved
  security.
- Eliminated internal HTTP/2 to HTTP/1 translation between proxies and workers.
- The proxy now adds a `Via` header to all HTTP responses.
- Changed `lscached` to use persistent EBS storage volumes instead of local
  disks when deployed to AWS.
- Added pod anti-affinity for `lscached-serve` and `proxy` services to
  distribute their replicas across nodes.
- Added support for fully custom OpenTelemetry collector configuration. See
  [OpenTelemetry Configuration] for details.

### 0.0.22 / 2025.01.08

- All deployments now use an extra layer of isolation, based on Google's gVisor,
  for additional security.
- Telemetry from deployments that use the `@opentelemetry/api` NPM package is
  now automatically exported via the OpenTelemetry pipeline.
- A new communication protocol between proxies and workers was implemented to
  improve stability when handling large HTTP requests or sending large HTTP
  responses.
- The Helm chart now allows for multiple deno-cluster installations in different
  namespaces within the same cluster.
- Different controller replicas are now spread out across multiple nodes for
  improved fault tolerance, by means of a pod anti-affinity rule.

### 0.0.21 / 2024.12.16

- Fixed a regression introduced in v0.0.20 where the controller would sometimes
  mark workers that had successfully booted as failed.

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

[AppConfig]: https://github.com/denoland/nextgen-install/wiki/AppConfig
[Cache]: https://github.com/denoland/nextgen-install/wiki/Cache
[Cluster API Auth]: https://github.com/denoland/nextgen-install/wiki/Cluster-API-Auth
[Dynamic TLS Certificates]: https://github.com/denoland/nextgen-install/wiki/Dynamic-TLS-Certificates
[OpenTelemetry Configuration]: https://github.com/denoland/nextgen-install/wiki/OpenTelemetry-Configuration
[Cluster Object API]: https://github.com/denoland/nextgen-install/wiki/Cluster-Object-API
[Deno.Kv]: https://docs.deno.com/api/deno/~/Deno.Kv
