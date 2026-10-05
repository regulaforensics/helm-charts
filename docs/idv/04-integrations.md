# Integrations

On its own, IDV can run workflows but cannot read a document or match a face. These capabilities are provided by two separate Regula services: Document Reader and Face API. Face and text search, metrics, and email are optional. All optional services described on this page are disabled by default.

| Integration | Required when | Default |
|---|---|---|
| Document Reader | A workflow reads identity documents | Disabled |
| Face API | A workflow uses face detection, comparison, or liveness | Disabled |
| OpenSearch or Atlas | Face or text search is enabled  | Disabled |
| StatsD | Metrics collection is needed | Disabled |
| SMTP | User invitations or email notifications are needed | Disabled |

## Document Reader

Document Reader reads and extracts data from identity documents. Install the
[`docreader`](../../charts/docreader/README.md) chart first.

**IDV needs Document Reader's Session API, which is off by default.** Workflows that require document reading fail without it.

In your `docreader` values, enable the session API:

```yaml
config:
  service:
    sessionApi:
      enabled: true
```

In your IDV values, set the following:

```yaml
config:
  services:
    docreader:
      enabled: true
      prefix: drapi
      url: "http://docreader.regula-docreader.svc.cluster.local:80"
```

`url` is the internal cluster address in the following format: 

`http://<service>.<namespace>.svc.cluster.local:80`

To find the service address, run:

```bash
kubectl get svc -n regula-docreader
```

Keep `prefix` set to `drapi`, which is the default value expected by SDKs.

## Face API

Face API provides face detection, comparison, and liveness. Install the
[`faceapi` chart](../../charts/faceapi/README.md), then enable it in your IDV values:

```yaml
config:
  services:
    faceapi:
      enabled: true
      mode: idv          # only supported value
      prefix: faceapi
      url: "http://faceapi.regula-faceapi.svc.cluster.local:80"
```

### Running on GPU

GPU is recommended for production workloads using Face API. Configure GPU support in the `faceapi` chart, not in the IDV configuration. **Both** of the following are required:

```yaml
image:
  tag: "<version>-gpu"     # a '-gpu' tag

resources:
  limits:
    nvidia.com/gpu: 1      # without this, the GPU tag does nothing
```

Your cluster also needs the
<a href="https://github.com/NVIDIA/k8s-device-plugin" target="_blank" rel="noopener noreferrer">NVIDIA device plugin</a>. GPU memory is more important than faster GPU processing. See [Requirements](01-requirements.md#face-api-and-gpu).

## Face and Text Search

Face and text search require one of the following:
- OpenSearch 2.19.0 or later
- MongoDB Atlas

Face search is also used by the Profile module.

To enable both search types with OpenSearch, add the following configuration to your `values.yaml`:

```yaml
config:
  faceSearch:
    enabled: true
    limit: 1000
    threshold: 0.75
    database:
      type: opensearch
      opensearch:
        host: "opensearch.example.com"
        port: "9200"
        useSsl: true
        verifyCerts: true
        username: "idv"
        password: ""          # comes from the Secret below
        dimension: 512
        method: "hnsw"

  textSearch:
    enabled: true
    limit: 1000
    database:
      type: opensearch
      opensearch:
        host: "opensearch.example.com"
        port: "9200"
        useSsl: true
        verifyCerts: true
        username: "idv"
        password: ""          # comes from the Secret below

env:
  - name: IDV_CONFIG__FACESEARCH__DATABASE__OPENSEARCH__PASSWORD
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: opensearchPassword }
  - name: IDV_CONFIG__TEXTSEARCH__DATABASE__OPENSEARCH__PASSWORD
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: opensearchPassword }
```

The `opensearchPassword` key is not part of the `idv-secrets` Secret created in [Production installation](03-install-production.md#3-configure-credentials). Add it before you install or upgrade:

```bash
kubectl patch secret idv-secrets -n regula-idv --type merge \
  -p '{"stringData":{"opensearchPassword":"<password>"}}'
```

For AWS OpenSearch Service, you can use IAM authentication instead of a password:

```yaml
config:
  faceSearch:
    database:
      opensearch:
        awsAuth:
          enabled: true
          region: "eu-central-1"
```

For MongoDB Atlas Vector Search, set `config.faceSearch.database.type: atlas` or `config.textSearch.database.type: atlas`.

### Indexer

A background service called Indexer builds the search indexes. It is deployed automatically when `faceSearch.enabled` or `textSearch.enabled` is set to `true`. No separate setting is needed:

```yaml
config:
  faceSearch:
    enabled: true
  textSearch:
    enabled: true
```

Confirm it is running:

```bash
kubectl get deploy -n regula-idv -l app.kubernetes.io/component=indexer
```

### Test without your own OpenSearch

For development and testing, set `opensearch.enabled: true` to deploy a single-node OpenSearch instance with IDV.

> **Note**
>
> Enabling `opensearch.enabled` replaces the external OpenSearch connection settings described above. If your external OpenSearch settings appear to be ignored, check whether `opensearch.enabled` is set to `true`.
>
> `opensearch.enabled` only deploys OpenSearch. Search itself must still be enabled with `config.faceSearch.enabled: true` or `config.textSearch.enabled: true`.

If your external OpenSearch settings appear to be ignored, check whether `opensearch.enabled` is enabled.

This configuration is not intended for production.

## Metrics

IDV sends StatsD metrics. To use an existing StatsD collector, configure its address in your `values.yaml`:

```yaml
config:
  metrics:
    statsd:
      enabled: true
      host: "statsd-exporter.monitoring.svc.cluster.local"
      port: 9125
      prefix: "idv"
```

Alternatively, you can let the chart deploy the StatsD exporter and connect IDV to it automatically:

```yaml
config:
  metrics:
    statsd:
      enabled: true
statsd:
  enabled: true
```

The bundled StatsD exporter is safe to use in production because it does not store application data. Note that
`statsd.enabled` overrides the `host` and `port` you set above.

The bundled exporter converts raw metrics into Prometheus metrics, including
`idv_backoffice_http_duration` and `idv_backoffice_http_request_total`. These metrics are recommended for scaling the `backoffice` service.

If you enable the bundled exporter (`statsd.enabled: true`), also enable `config.metrics.statsd.enabled: true`. Otherwise the exporter runs but receives no metrics. The chart prints a note during installation in this case.

## Email

Without SMTP, user invitations and email notifications are not available. To enable them, configure the following:

```yaml
config:
  smtp:
    enabled: true
    host: "smtp.example.com"
    port: 587
    tls: true
    username: ""    # comes from the Secret below
    password: ""

env:
  - name: IDV_CONFIG__SMTP__USERNAME
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: smtpUsername }
  - name: IDV_CONFIG__SMTP__PASSWORD
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: smtpPassword }
```

The `smtpUsername` and `smtpPassword` keys are not part of the `idv-secrets` Secret created in [Production installation](03-install-production.md#3-configure-credentials). Add them before you install or upgrade:

```bash
kubectl patch secret idv-secrets -n regula-idv --type merge \
  -p '{"stringData":{"smtpUsername":"<username>","smtpPassword":"<password>"}}'
```

Links in outgoing email use `config.baseUrl`, so it must be correct.

## Next

- [Configuration](05-configuration.md) — configure how these settings reach the application
- [Authentication and users](06-auth-and-users.md) — configure sign-in and roles
