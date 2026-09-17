# Integrations

On its own, IDV can run workflows but cannot read a document or match a face. Those come from two
other Regula services. Search, metrics, and email are optional too.

Everything on this page is off by default.

## Document Reader

Reads and extracts data from identity documents. Install the
[`docreader` chart](../../charts/docreader/README.md) first.

**IDV needs Document Reader's Session API, which is off by default.** Workflows fail without it.

In your `docreader` values:

```yaml
config:
  service:
    sessionApi:
      enabled: true
```

In your IDV values:

```yaml
config:
  services:
    docreader:
      enabled: true
      prefix: drapi
      url: "http://docreader.regula-docreader.svc.cluster.local:80"
```

`url` is the internal cluster address, shaped like
`http://<service>.<namespace>.svc.cluster.local:80`. Find yours with
`kubectl get svc -n regula-docreader`.

Leave `prefix` as `drapi` — client SDKs expect the default.

## Face API

Face detection, comparison, and liveness. Install the
[`faceapi` chart](../../charts/faceapi/README.md), then:

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

Recommended for production. Configured in the `faceapi` chart, not here, and needs **both** parts:

```yaml
image:
  tag: "<version>-gpu"     # a '-gpu' tag

resources:
  limits:
    nvidia.com/gpu: 1      # without this, the GPU tag does nothing
```

Your cluster also needs the
[NVIDIA device plugin](https://github.com/NVIDIA/k8s-device-plugin). More GPU memory matters more
than faster cores — see [Requirements](01-requirements.md#face-api-and-gpu).

## Face and text search

Both need OpenSearch 2.19.0+ or MongoDB Atlas. Face search also powers the Profile module.

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

On AWS OpenSearch Service, use IAM instead of a password:

```yaml
config:
  faceSearch:
    database:
      opensearch:
        awsAuth:
          enabled: true
          region: "eu-central-1"
```

For MongoDB Atlas Vector Search, set `config.faceSearch.database.type: atlas`.

### The Indexer

A background service called the Indexer builds the search indexes. It is deployed automatically when
either `faceSearch.enabled` or `textSearch.enabled` is `true` — no separate setting is needed:

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

### Testing without your own OpenSearch

`opensearch.enabled: true` installs a single-node OpenSearch for development. It **replaces all the
search connection settings above.** If yours seem to be ignored, check this switch. Not for
production.

## Metrics

IDV sends StatsD metrics. Point it at your collector:

```yaml
config:
  metrics:
    statsd:
      enabled: true
      host: "statsd-exporter.monitoring.svc.cluster.local"
      port: 9125
      prefix: "idv"
```

Or let the chart deploy the exporter and connect itself automatically:

```yaml
config:
  metrics:
    statsd:
      enabled: true
statsd:
  enabled: true
```

Unlike the bundled databases, this one is safe in production — it holds no data. Note that
`statsd.enabled` overrides the `host` and `port` you set above.

The bundled exporter converts raw metrics into Prometheus ones, including
`idv_api_http_duration` and `idv_api_http_request_total` — the two recommended for scaling the API.

Turning on one switch but not the other is a common slip; the chart warns you at install time.

## Email

Needed for user invitations and notifications:

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

Links in outgoing email use `config.baseUrl`, so it must be correct.

## Next

- [Configuration](05-configuration.md) — how these settings reach the application
- [Authentication and users](06-auth-and-users.md) — sign-in and roles
