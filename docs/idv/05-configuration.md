# Configuration

This section describes configuration settings: where they are kept, how they are applied, and which settings should be configured through `values.yaml`.

## How it works

IDV reads one file, `config.yaml`. You never write it directly. Instead:

1. You set values under `config:` in your `values.yaml`.
2. The chart turns them into the ConfigMap.
3. The ConfigMap is mounted into all five services as `/app/config.yaml`.
4. Environment variables can override any single field at startup.

Two things follow from this:

- **Anything under `config:` is stored in plain text** in the ConfigMap and can be read by anyone with access to the namespace. Do not put credentials there. Use a Secret instead (see below [Passing secrets](#passing-secrets)).
- **All five services share one config.** Changing it restarts all of them.

To see the config your cluster is actually using:

```bash
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}'
```

## Passing secrets

Never put passwords, keys, or connection strings under `config:`. Put them in a Secret and
reference them from the top-level `env:` list:

```yaml
env:
  - name: IDV_CONFIG__FERNETKEY
    valueFrom:
      secretKeyRef:
        name: idv-secrets
        key: fernetKey
```

The variable name is `IDV_CONFIG__` plus the setting's path, in capitals, with **two** underscores
between each level:

| Setting | Variable |
|---|---|
| `fernetKey` | `IDV_CONFIG__FERNETKEY` |
| `mongo.url` | `IDV_CONFIG__MONGO__URL` |
| `messageBroker.url` | `IDV_CONFIG__MESSAGEBROKER__URL` |
| `storage.s3.accessKey` | `IDV_CONFIG__STORAGE__S3__ACCESSKEY` |
| `storage.az.connectionString` | `IDV_CONFIG__STORAGE__AZ__CONNECTIONSTRING` |
| `smtp.password` | `IDV_CONFIG__SMTP__PASSWORD` |
| `faceSearch.database.opensearch.password` | `IDV_CONFIG__FACESEARCH__DATABASE__OPENSEARCH__PASSWORD` |

Items in the list are numbered from zero, so the first OAuth2 provider's secret is
`IDV_CONFIG__OAUTH2__PROVIDERS__0__SECRET`.

The variable overrides the value in the config file. It's expected that the placeholder you left under `config:` remains visible in
the ConfigMap.

### `env` vs `config.env`

Watch out: `env` and `config.env` are different.

| | What it is |
|---|---|
| `env:` (top level) | Kubernetes environment variables. **Use this for secrets.** |
| `config.env:` | A label for the environment, such as `prod`. Nothing else. |

Putting a `valueFrom` block under `config.env` does **not** create the variable you intended. It may write something unexpected into the config file and keeps your original setting unchanged, with no error:

```yaml
# WRONG — does nothing
config:
  env:
    - name: IDV_CONFIG__FERNETKEY
      valueFrom:
        secretKeyRef: { name: idv-secrets, key: fernetKey }
```

```yaml
# RIGHT — top level
env:
  - name: IDV_CONFIG__FERNETKEY
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: fernetKey }
```

Check that the variable is added to the deployment:

```bash
kubectl set env deploy/idv-api --list -n regula-idv | grep IDV_CONFIG
```

## Storage

Set `config.storage.type` to `s3`, `az`, or `gcs`. Kubernetes deployments use object storage; local
filesystem storage (`fs`) is not available.

Through this chart, IDV stores eight kinds of data: `sessions`, `persons`, `workflows`, `userFiles`,
`locales`, `assets`, `tempFiles`, and `banlists`. Each needs a location that already exists. They can
share one bucket using different prefixes, which is what the
[production example](03-install-production.md#5-configure-valuesyaml) does. For S3-compatible storage, replace the example bucket name with your bucket name. Keep the prefixes unchanged unless you have a specific reason to customize them.

The chart does not create buckets for you, except when using the MinIO subchart.

For Azure, only `prefix` is used and `bucket` is ignored. For Google Cloud, add the service account
key as a Secret:

```yaml
config:
  storage:
    type: gcs
    gcs:
      gcsKeyJsonSecretName: gcs-credentials
```

```bash
kubectl create secret generic gcs-credentials \
  -n regula-idv --from-file=gcs_key.json=./key.json
```

## Scheduled clean-up jobs

The Scheduler runs housekeeping tasks on a timer. **Most timers use six fields and start with
seconds**, so `*/10 * * * * *` means every ten seconds, not every ten minutes. When changing one,
copy the shape of the existing default.

By default, **session data is kept forever.** If you have a retention policy, set `cleanSessions`:

```yaml
config:
  services:
    scheduler:
      jobs:
        cleanSessions:
          cron: '0 0 3 * * *'   # 03:00 daily
          keepFor: 90d
```

`keepFor` accepts values like `30d`, `1w`, `1y`.

## Careful: subchart switches overwrite your settings

Turning on a bundled dependency replaces the matching settings you supplied. This is useful for demo but can be confusing for other environments. **If a connection setting seems to be ignored, check these first.**

| Switch | Overwrites |
|---|---|
| `mongodb.enabled` | `config.mongo.url` |
| `rabbitmq.enabled` | `config.messageBroker.url` |
| `minio.enabled` | all of `config.storage.s3` |
| `opensearch.enabled` | all face and text search connection settings |
| `statsd.enabled` | `config.metrics.statsd.host` and `port` |

For production deployments, keep the first four disabled and use externally managed services instead. The bundled MongoDB, RabbitMQ, MinIO, and OpenSearch instances are intended for development and testing, not as production data stores. 

`statsd` is different: it is a stateless metrics exporter with nothing to lose, and enabling
it is a reasonable choice in production.

## Settings configured outside the chart

Chart `1.16.0` covers the settings needed for a standard Kubernetes deployment. 

> **Important:** These settings are not supported through `config:` in the Helm chart. Adding them there has no effect:

| Setting | Feature |
|---|---|
| `mode` | Always `cluster` for Kubernetes deployments |
| `storage.type: fs` | Local filesystem storage |
| `storage.<location>.folder` | Folder paths, available for `tempFiles` |
| `metrics.alerts`, `metrics.database` | Prometheus alert access and database-backed metrics |
| `services.audit.api.keepFor` | API audit retention, separate from `user.keepFor` |
| `deviceMessageTracking` | Device message history |
| `replicationBus`, `services.mongoReplicator`, `services.searchReplicator` | Multi-site replication |
| Advanced `saml.providers[].security` options | Signature and digest algorithms, assertion signing |

Contact Regula support if your deployment needs one of these. Editing the ConfigMap directly is not a
workaround, Helm replaces it on the next upgrade.

## Next

- [Authentication and users](06-auth-and-users.md)
- [Operations](07-operations.md)
- Every available setting → [chart README](../../charts/idv/README.md)
