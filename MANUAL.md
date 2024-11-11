# Manual

## Making a Deployment

The command line tool available at `./tools/ddng` is used to package and deploy
applications. The application has few external dependencies — [`deno`][deno]
must be installed, as well as the [AWS cli][aws].

## Usage

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

## Configuration

### AWS

The AWS needs to be configured to use the S3 bucket that Deno Deploy Next Gen
uses on the backend. In case this isn't already the case, follow [AWS's
instructions][aws-configure].

### Minio

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

### Deno

The tool communicates with your cluster using the public domain, there is no
configuration required here.

## Targeting A Specific Isolate

Normally, requests are load balanced across V8 isolates. In order to target a
specific isolate, you can add the `x-deno-isolate-instance-id` header or the
`deno_isolate_instance_id` query string parameter to your request.

When an isolate ID is specified, all requests with the same isolate ID are
_guaranteed_ to be handled by the same isolate. This isolate is dedicated to
this ID and it doesn't handle any requests with a different isolate id or
requests that don't have an isolate ID at all.

These "dedicated" isolates with an ID are subject to normal time-out behavior.

[deno]: https://deno.com
[aws]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[aws-configure]: https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-configure.html
