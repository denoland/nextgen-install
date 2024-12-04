# Deno Deploy NextGen

**Deno Deploy NextGen** is a self-hosted, serverless platform designed to run on
any Kubernetes cluster. It brings the power of Deno Deploy to your
infrastructure, enabling fast deployment of modern JavaScript frameworks like
Next.js, while delivering enterprise-grade scalability and multi-tenant
security.

## Key Features

- **Self-host in Kubernetes:** Run the Deno Deploy infrastructure in your own
  Kubernetes environment.
- **Instant JavaScript Hosting:** Easily deploy subdomains for Next.js and other
  JavaScript frameworks.
- **Effortless Scaling:** A battle-tested serverless architecture that scales
  from zero to millions of apps.
- **Robust Multi-tenant Security:** Safely run untrusted code at scale with
  strong multi-tenant support.
- **Built-in Observability:** Get integrated logging, metrics, and tracing
  through OpenTelemetry.

## Product Overview

Deno Deploy NextGen is built for teams seeking flexibility in running Deno and
JavaScript-based serverless workloads within their own infrastructure. Powered
by Kubernetes and cloud-native blob storage, it enables fast global deployments
with minimal cold start times, offering a highly productive and cost-efficient
development platform. You can easily attach subdomains to host new apps and rely
on automatic scaling as demand increases. The platform also supports critical
enterprise needs like secure multi-tenancy and observability with OpenTelemetry.

Currently, Deno Deploy NextGen supports AWS and Azure environments, with future
plans to extend support to other cloud providers and bare-metal setups.

## Installation

For detailed installation instructions based on your cloud provider, refer to
the following files:

- [AWS Installation Instructions](aws/README.md)
- [Azure Installation Instructions](azure/README.md)

These guides will help you set up Deno Deploy NextGen on your preferred cloud
and walk you through the process of deploying your own serverless
infrastructure.

## Documentation

- [Release notes](./RELEASE_NOTES.md)
- [Manual](./MANUAL.md)
