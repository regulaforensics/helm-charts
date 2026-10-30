# IDV Helm Chart

Regula Identity Verification Platform. On-premise and cloud deployment.

> **Installation and configuration guides live in [`docs/idv/`](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/README.md).**

- [About](#about)
- [Prerequisites](#prerequisites)
- [Quick Reference](#quick-reference)
- [Backoffice Base URL](#backoffice-base-url)
- [Upgrading to 2.0.0 (IDV 3.10)](#upgrading-to-200-idv-310)
- [Chart Parameters](#chart-parameters)
- [In Cluster TLS](#in-cluster-tls-trusted-ca-bundle)
- [Subchart Parameters](#subchart-parameters)
- [Deployed Components](#deployed-components)
- [KEDA Autoscaling](#keda-autoscaling)

## About
>
> This file is the parameter reference (see [Chart Parameters](#chart-parameters) below). If you are installing IDV for the first time, start with
> the [documentation index](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/README.md) instead — it covers requirements, a demo quickstart, the
> production installation, integrations, and troubleshooting in order.

| Guide | |
|---|---|
| [Requirements](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/01-requirements.md) | Dependencies, versions, sizing |
| [Quickstart](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/02-quickstart.md) | Working demo in ~10 minutes |
| [Production installation](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/03-install-production.md) | External dependencies, secrets, TLS |
| [Integrations](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/04-integrations.md) | Document Reader, Face API, search, metrics |
| [Configuration](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/05-configuration.md) | Config pipeline and overrides |
| [Authentication and users](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/06-auth-and-users.md) | First admin, SSO, roles |
| [Operations](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/07-operations.md) | Upgrades, scaling, backups |
| [Troubleshooting](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/08-troubleshooting.md) | Common failures |

## Prerequisites

- Helm >= 3.10
- Kubernetes >= 1.23
- A `regula.license` file from the [Client Portal](https://client.regulaforensics.com/), loaded
  into a Secret

## Quick Reference

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update

kubectl create namespace regula-idv
kubectl create secret generic idv-license \
  -n regula-idv --from-file=regula.license=./regula.license

helm install idv regulaforensics/idv \
  -n regula-idv \
  --set licenseSecretName=idv-license \
  -f values.yaml
```

### Demo install, with bundled dependencies

For evaluation only. Deploys MongoDB, RabbitMQ, and MinIO alongside IDV and wires them up
automatically, so no connection settings are needed:

```console
helm install idv regulaforensics/idv \
  -n regula-idv \
  --set licenseSecretName=idv-license \
  --set mongodb.enabled=true \
  --set rabbitmq.enabled=true \
  --set minio.enabled=true \
  --wait --timeout 10m
```

These bundled data stores are single-node, use well-known passwords, and are not backed up. **Do not
use them in production** — see [Quickstart](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/02-quickstart.md) for the full walkthrough and
[Production install](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/03-install-production.md) for a real deployment.

### First user

A fresh install has **no users**. Create the first admin before you can log in:

```console
kubectl exec -n regula-idv deploy/idv-backoffice -- \
  idv user create --name admin --password '<password>' --email admin@example.com --roles admin
```

Upgrade and uninstall:

```console
helm upgrade idv regulaforensics/idv -n regula-idv -f values.yaml
helm uninstall idv -n regula-idv
```

## Backoffice Base URL

The Backoffice can advertise its own base URL. When `config.services.backoffice.baseUrl` is not set
(`null`), the root `config.baseUrl` is used, so existing installations keep working unchanged.

```yaml
config:
  # Fallback when the service does not define its own baseUrl
  baseUrl: "https://idv.example.com"
  services:
    backoffice:
      baseUrl: "https://api.example.com"
```

## Upgrading to 2.0.0 (IDV 3.10)

Chart 2.0.0 ships IDV 3.10, which renames the `api` component to `backoffice`. Existing values keep
working, but read this section before upgrading from 1.x.

**Values**

- The top-level `api:` and `config.services.api` keys are still honored. They are merged over the
  `backoffice` defaults and the install prints a `DEPRECATED` note. Move them to `backoffice:` and
  `config.services.backoffice` when convenient.
- `config.services.backoffice.cors`, `config.mobile`, `config.smtp`, `config.oauth2`, `config.saml`
  and `config.rateLimit` are deprecated. They are only used for the initial migration into the
  platform database and will be removed from the chart in the next release.

**Resources**

- The Backoffice Deployment, HPA, PDB, ScaledObject, TriggerAuthentication and HTTPRoute are renamed
  from `<fullname>-api` to `<fullname>-backoffice`. The container is renamed from `api` to
  `backoffice` and now runs `idv backoffice start`. Update anything that refers to the old names,
  such as `kubectl logs -c api`, log pipelines, dashboards and alerts.
- If `backoffice.autoscaling.keda.triggers[].authenticationRef.name` (or the old `api.*` equivalent)
  points at `<fullname>-api`, change it to `<fullname>-backoffice`.
- The pre-3.10 Service `<fullname>-api` is kept and points at the Backoffice pods, so existing clients
  and load balancers keep working. It copies the `backoffice.service` settings, so with
  `type: LoadBalancer` both Services get a load balancer. Switch clients to `<fullname>-backoffice`,
  then set `backoffice.legacyApiService.enabled: false`.
- With `networkPolicy.enabled: true`, the NetworkPolicy now selects the IDV pods. In 1.x its selector
  matched no pods, so the policy starts being enforced after the upgrade. Review
  `networkPolicy.ingress` and `networkPolicy.egress` first.
- The Indexer is now also deployed when only `config.faceSearch.enabled` is `true`.

**Storage**

- The per-entity `config.storage.<entity>.location.bucket` / `location.folder` keys were replaced by
  a single backend-level `config.storage.s3.bucket` (or `gcs.bucket` / `az.container`) plus
  `location.prefix` per entity. If your values still use the old per-entity keys, they are still
  honored and rendered into the app config (the install prints a `DEPRECATED` note), so your data
  path is preserved. Migrate to the single-bucket layout when convenient; the old keys are removed
  in IDV 5.0.
- Azure: the chart now renders `config.storage.az.container`. Set it explicitly before upgrading.
- The default temp files location changed from prefix `tmp` with folder `files` to prefix `files/tmp`.

> [!NOTE]
> The Backoffice is briefly unavailable during this upgrade on both the `<fullname>-api` and
> `<fullname>-backoffice` Service names. Because the component is renamed, the old Deployment is
> replaced rather than rolled, so there is a short gap (typically about 20 seconds) until the new
> pods are ready. The exact duration depends on your cluster (image pull, node capacity, probe
> timings, replica count). Plan the upgrade for a maintenance window.

## Things to get right before production

- **Override `config.fernetKey`.** The default is a real, working key published in this
  repository, so data encrypted with it is not protected. The chart prints a warning after install
  if the default is still in use, or if no key is set at all. Back the key up: without it,
  encrypted database fields are unrecoverable, and changing it later makes existing data unreadable.
- **Set `config.baseUrl`** to the URL clients actually reach. It is embedded in QR codes and
  redirects; a mismatch breaks capture flows while the portal still loads.
- **Pass credentials through the top-level `env` list**, not through `config`. Anything under
  `config` is rendered into a ConfigMap in plain text. See
  [Configuration](https://github.com/regulaforensics/helm-charts/blob/main/docs/idv/05-configuration.md#passing-secrets).
- **Keep the bundled data stores disabled** (`mongodb`, `rabbitmq`, `minio`, `opensearch`). The
  `statsd` exporter is stateless and safe to enable.

### Injecting a secret value

Set any config field from a Secret using the top-level `env` list. The variable name is
`IDV_CONFIG__` plus the config path, uppercased, with double underscores between levels:

```yaml
env:
  - name: IDV_CONFIG__FERNETKEY
    valueFrom:
      secretKeyRef:
        name: idv-secrets
        key: fernetKey
```

> `config.env` is **not** the same thing. It is an application config field holding an environment
> *name* (such as `prod`) and is rendered into `config.yaml` as a string. A `valueFrom` block placed
> there creates no environment variable and silently corrupts the config file. Always use the
> top-level `env`.

## Chart parameters

> **Note:** In version 3.10, the `api` component was renamed to `backoffice`. The `api` component name remains supported for backward compatibility in version 3.10, but we recommend updating your configuration to use `backoffice`.
>
> During the upgrade, `backoffice` is unavailable for about 20 seconds. Plan the upgrade for a maintenance window. See [Upgrading to 2.0.0](#upgrading-to-200-idv-310).

| Parameter | Description | Default |
|-----------------------------------------------------------|---------------------------------------------------|-----------------------------------|
| `nameOverride`                                            | Override the chart name                           | `""`                              |
| `fullnameOverride`                                        | Override the full chart name                      | `""`                              |
| `commonLabels`                                            | Labels applied to all resources                   | `{}`                              |
| `podAnnotations`                                          | Pod annotations                                   | `{}`                              |
| `podSecurityContext`                                      | Pod security context                              | `{}`                              |
| `securityContext`                                         | Container security context                        | `{}`                              |
| `extraVolumes`                                            | Additional volumes added to all IDV deployments   | `[]`                              |
| `extraVolumeMounts`                                       | Additional volume mounts added to all IDV deployments | `[]`                          |
| `tls.trustedCABundle.configMapName`                       | ConfigMap holding a CA bundle to trust for in-cluster TLS (e.g. from cert-manager trust-manager). Empty disables the feature | `""` |
| `tls.trustedCABundle.key`                                 | Key in the ConfigMap that holds the PEM CA bundle | `ca-bundle.pem`                   |
| `tls.trustedCABundle.mountPath`                           | Directory the bundle is mounted at (use for e.g. MongoDB `tlsCAFile`) | `/etc/regula/tls`             |
| `tls.trustedCABundle.caStorePaths`                        | CA-store file(s) overlaid with the bundle (image-version-dependent; update on Python upgrade) | `[botocore, certifi, system]` |
| `versionSha`                                              | Version SHA tag                                   | `latest`                          |
| `image.repository`                                        | Image repository                                  | `regulaforensics/idv-coordinator` |
| `image.pullPolicy`                                        | Image pull policy                                 | `IfNotPresent`                    |
| `image.tag`                                               | Image tag override                                | `""`                              |
| `imagePullSecrets`                                        | Secrets for private registries                    | `{}`                              |
| `licenseSecretName`                                       | Name of existing secret containing regula.license | `null`                            |
| `api.*`                                                   | **Deprecated (renamed to `backoffice.*` in 3.10).** Still honored; merged over the `backoffice` values and prints a DEPRECATED note on install. | — |
| `backoffice.replicas`                                            | Number of Backoffice replicas                            | `1`                               |
| `backoffice.nodeSelector`                                        | Node selector for Backoffice pods                        | `{}`                              |
| `backoffice.tolerations`                                         | Tolerations for Backoffice pods                          | `[]`                              |
| `backoffice.affinity`                                            | Affinity rules for Backoffice pods                       | `{}`                              |
| `backoffice.resources`                                           | Resource requests/limits for Backoffice                 | `{}`                              |
| `backoffice.topologySpreadConstraints`                           | Topology spread constraints for Backoffice              | `[]`                              |
| `backoffice.terminationGracePeriodSeconds`                       | Backoffice pod termination grace period                  | `45`                              |
| `backoffice.lifecycle`                                           | Backoffice pod lifecycle hooks                           | `{}`                              |
| `backoffice.service.type`                                        | Backoffice service type                                  | `ClusterIP`                       |
| `backoffice.service.port`                                        | Backoffice service port                                  | `80`                              |
| `backoffice.service.annotations`                                 | Backoffice service annotations                           | `{}`                              |
| `backoffice.service.loadBalancerSourceRanges`                    | LoadBalancer source ranges for Backoffice                | `[]`                              |
| `backoffice.legacyApiService.enabled`                            | Also create the pre-3.10 Service `<fullname>-api` pointing at the Backoffice pods (deprecated; keeps old clients working). Set `false` once nothing uses the old name. | `true` |
| `backoffice.autoscaling.enabled`                                 | Enable Backoffice autoscaling                            | `false`                           |
| `backoffice.autoscaling.minReplicas`                             | Minimum Backoffice replicas                              | `1`                               |
| `backoffice.autoscaling.maxReplicas`                             | Maximum Backoffice replicas                              | `100`                             |
| `backoffice.autoscaling.targetCPUUtilizationPercentage`          | Target CPU utilization percent                    | `80`                              |
| `backoffice.autoscaling.targetMemoryUtilizationPercentage`       | Target memory utilization percent                 | `80`                              |
| `backoffice.autoscaling.keda.enabled`                            | Enable KEDA for Backoffice                              | `false`                           |
| `backoffice.autoscaling.keda.minReplicaCount`                    | KEDA minimum replica count for Backoffice               | `1`                               |
| `backoffice.autoscaling.keda.maxReplicaCount`                    | KEDA maximum replica count for Backoffice                | `100`                             |
| `backoffice.autoscaling.keda.cooldownPeriod`                     | KEDA cooldown period (seconds) for Backoffice            | `300`                             |
| `backoffice.autoscaling.keda.pollingInterval`                    | KEDA polling interval (seconds) for Backoffice           | `30`                              |
| `backoffice.autoscaling.keda.advanced.scaleUp.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling up | `180`                    |
| `backoffice.autoscaling.keda.advanced.scaleDown.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling down | `300`                |
| `backoffice.autoscaling.keda.triggers`                           | KEDA triggers for Backoffice                             | `[]`                              |
| `backoffice.autoscaling.keda.TriggerAuthentication`              | KEDA TriggerAuthentication for Backoffice                | `null`                            |
| `backoffice.autoscaling.keda.fallback`                           | KEDA fallback config when metrics unavailable     | `null`                            |
| `backoffice.autoscaling.keda.fallback.failureThreshold`          | Errors before fallback activates                  | `3`                               |
| `backoffice.autoscaling.keda.fallback.replicas`                  | Replica count during fallback                     | `1`                               |
| `backoffice.podDisruptionBudget.enabled`                         | Enable PDB for Backoffice                                | `false`                           |
| `backoffice.podDisruptionBudget.config.maxUnavailable`           | PDB maxUnavailable for Backoffice                        | `~`                               |
| `backoffice.podDisruptionBudget.config.minAvailable`             | PDB minAvailable for Backoffice                          | `1`                               |
| `backoffice.probes.livenessProbe.enabled`                        | Enable Backoffice liveness probe                         | `true`                            |
| `backoffice.probes.livenessProbe.initialDelaySeconds`            | Liveness initial delay                            | `5`                               |
| `backoffice.probes.livenessProbe.timeoutSeconds`                 | Liveness timeout                                  | `5`                               |
| `backoffice.probes.livenessProbe.periodSeconds`                  | Liveness period                                   | `10`                              |
| `backoffice.probes.livenessProbe.successThreshold`               | Liveness success threshold                        | `1`                               |
| `backoffice.probes.livenessProbe.failureThreshold`               | Liveness failure threshold                        | `3`                               |
| `backoffice.probes.readinessProbe.enabled`                       | Enable Backoffice readiness probe                        | `true`                            |
| `backoffice.probes.readinessProbe.initialDelaySeconds`           | Readiness initial delay                           | `5`                               |
| `backoffice.probes.readinessProbe.timeoutSeconds`                | Readiness timeout                                 | `5`                               |
| `backoffice.probes.readinessProbe.periodSeconds`                 | Readiness period                                  | `10`                              |
| `backoffice.probes.readinessProbe.successThreshold`              | Readiness success threshold                       | `1`                               |
| `backoffice.probes.readinessProbe.failureThreshold`              | Readiness failure threshold                       | `3`                               |
| `backoffice.probes.startupProbe.enabled`                         | Enable Backoffice startup probe                          | `false`                           |
| `backoffice.probes.startupProbe.initialDelaySeconds`             | Startup initial delay                             | `10`                              |
| `backoffice.probes.startupProbe.timeoutSeconds`                  | Startup timeout                                   | `5`                               |
| `backoffice.probes.startupProbe.periodSeconds`                   | Startup period                                    | `10`                              |
| `backoffice.probes.startupProbe.successThreshold`                | Startup success threshold                         | `1`                               |
| `backoffice.probes.startupProbe.failureThreshold`                | Startup failure threshold                         | `3`                               |
| `workflow.replicas`                                       | Number of Workflow replicas                       | `1`                               |
| `workflow.nodeSelector`                                   | Node selector for Workflow pods                   | `{}`                              |
| `workflow.tolerations`                                    | Tolerations for Workflow pods                     | `[]`                              |
| `workflow.affinity`                                       | Affinity rules for Workflow pods                  | `{}`                              |
| `workflow.resources`                                      | Resource requests/limits for Workflow             | `{}`                              |
| `workflow.topologySpreadConstraints`                      | Topology spread for Workflow                      | `[]`                              |
| `workflow.autoscaling.enabled`                            | Enable Workflow autoscaling                       | `false`                           |
| `workflow.autoscaling.minReplicas`                        | Minimum Workflow replicas                         | `1`                               |
| `workflow.autoscaling.maxReplicas`                        | Maximum Workflow replicas                         | `100`                             |
| `workflow.autoscaling.targetCPUUtilizationPercentage`     | Workflow target CPU percent                       | `80`                              |
| `workflow.autoscaling.targetMemoryUtilizationPercentage`  | Workflow target memory percent                    | `80`                              |
| `workflow.autoscaling.keda.enabled`                       | Enable KEDA for Workflow                          | `false`                           |
| `workflow.autoscaling.keda.minReplicaCount`               | KEDA minimum replica count for Workflow           | `1`                               |
| `workflow.autoscaling.keda.maxReplicaCount`               | KEDA maximum replica count for Workflow           | `100`                             |
| `workflow.autoscaling.keda.cooldownPeriod`                | KEDA cooldown period (seconds) for Workflow       | `300`                             |
| `workflow.autoscaling.keda.pollingInterval`               | KEDA polling interval (seconds) for Workflow      | `30`                              |
| `workflow.autoscaling.keda.advanced.scaleUp.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling up | `180`               |
| `workflow.autoscaling.keda.advanced.scaleDown.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling down | `300`           |
| `workflow.autoscaling.keda.triggers`                      | KEDA triggers for Workflow                        | `[]`                              |
| `workflow.autoscaling.keda.TriggerAuthentication`         | KEDA TriggerAuthentication for Workflow           | `null`                            |
| `workflow.autoscaling.keda.fallback`                      | KEDA fallback config when metrics unavailable     | `null`                            |
| `workflow.autoscaling.keda.fallback.failureThreshold`     | Errors before fallback activates                  | `3`                               |
| `workflow.autoscaling.keda.fallback.replicas`             | Replica count during fallback                     | `1`                               |
| `workflow.podDisruptionBudget.enabled`                    | Enable PDB for Workflow                           | `false`                           |
| `workflow.podDisruptionBudget.config.maxUnavailable`      | PDB maxUnavailable for Workflow                   | `~`                               |
| `workflow.podDisruptionBudget.config.minAvailable`        | PDB minAvailable for Workflow                     | `1`                               |
| `scheduler.replicas`                                      | Number of Scheduler replicas                      | `1`                               |
| `scheduler.nodeSelector`                                  | Node selector for Scheduler pods                  | `{}`                              |
| `scheduler.tolerations`                                   | Tolerations for Scheduler pods                    | `[]`                              |
| `scheduler.affinity`                                      | Affinity rules for Scheduler pods                 | `{}`                              |
| `scheduler.resources`                                     | Resource requests/limits for Scheduler            | `{}`                              |
| `scheduler.topologySpreadConstraints`                     | Topology spread for Scheduler                     | `[]`                              |
| `audit.replicas`                                          | Number of Audit replicas                          | `1`                               |
| `audit.nodeSelector`                                      | Node selector for Audit pods                      | `{}`                              |
| `audit.tolerations`                                       | Tolerations for Audit pods                        | `[]`                              |
| `audit.affinity`                                          | Affinity rules for Audit pods                     | `{}`                              |
| `audit.resources`                                         | Resource requests/limits for Audit                | `{}`                              |
| `audit.topologySpreadConstraints`                         | Topology spread for Audit                         | `[]`                              | 
| `indexer.replicas`                                        | Number of Indexer replicas                        | `1`                               |
| `indexer.nodeSelector`                                    | Node selector for Indexer pods                    | `{}`                              |
| `indexer.tolerations`                                     | Tolerations for Indexer pods                      | `[]`                              |
| `indexer.affinity`                                        | Affinity rules for Indexer pods                   | `{}`                              |
| `indexer.resources`                                       | Resource requests/limits for Indexer              | `{}`                              |
| `indexer.topologySpreadConstraints`                       | Topology spread for Indexer                       | `[]`                              |
| |
| `config.baseUrl`                                          | Root application base URL; fallback for services without their own `baseUrl` | `"http://idv.example.com"` |
| `config.fernetKey`                                        | Fernet encryption key. The default is a publicly known key; override it for production | Public default key |
| `config.tenant`                                           | Tenant name/id used for named broker topics       | `null`                            |
| `config.identifier`                                       | Instance identifier                               | `null`                            |
| `config.basicAuth.enabled`                                | Enable username/password sign-in                  | `true`                            |
| `config.services.backoffice.baseUrl`                             | Backoffice base URL (falls back to `config.baseUrl` when unset) | `null`                     |
| `config.services.backoffice.port`                                | Internal Backoffice port                                 | `8000`                            |
| `config.services.backoffice.host`                                | Backoffice bind host                                     | `0.0.0.0`                         |
| `config.services.backoffice.workers`                             | Backoffice worker count                                  | `auto`                            |
| `config.services.backoffice.threads`                             | Backoffice threads count                                 | `auto`                            |
| `config.services.backoffice.keepalive`                           | Keepalive seconds                                 | `120`                             |
| `config.services.backoffice.timeout`                             | Request timeout seconds                           | `120`                             |
| `config.services.backoffice.cors.enabled`                        | **Deprecated.** Enable CORS                       | `false`                           |
| `config.services.backoffice.cors.origins`                        | **Deprecated.** Allowed origins                   | `"*"`                             |
| `config.services.backoffice.cors.methods`                        | **Deprecated.** Allowed methods                   | `"*"`                             |
| `config.services.backoffice.cors.headers`                        | **Deprecated.** Allowed headers                   | `"*"`                             |
| `config.services.backoffice.cors.maxAge`                         | **Deprecated.** CORS max age seconds              | `0`                               |
| `config.services.backoffice.maxBodySize`                         | Max body size                                     | `64Mi`                            |
| `config.services.backoffice.openapi`                             | Enable OpenAPI docs                               | `false`                           |
| `config.services.api.*`                                          | **Deprecated (renamed to `config.services.backoffice.*` in 3.10).** Still honored; merged over the `backoffice` values. | — |
| `config.services.workflow.workers`                        | Workflow service workers                          | `auto`                            |
| `config.services.workflow.threads`                        | Workflow service threads per worker               | `32`                              |
| `config.services.scheduler.jobs.reloadWorkflows.cron`     | Cron for reloading workflows                      | `"*/15 * * * * *"`                |
| `config.services.scheduler.jobs.expireSessions.cron`      | Cron for expiring sessions                        | `"*/10 * * * * *"`                |
| `config.services.scheduler.jobs.cleanSessions.cron`       | Cron for cleaning sessions                        | `null`                            |
| `config.services.scheduler.jobs.cleanSessions.keepFor`    | Keep session data for                             | `null`                            |
| `config.services.scheduler.jobs.expireDeviceLogs.cron`    | Cron for expiring device logs                     | `"*/5 * * * *"`                   |
| `config.services.scheduler.jobs.expireDeviceLogs.keepFor` | Keep device logs for                              | `"30d"`                           |
| `config.services.scheduler.jobs.reloadLocales.cron`       | Cron for reloading locales                        | `"*/15 * * * * *"`                |
| `config.services.scheduler.jobs.cronWorkflow.cron`        | Cron for generic workflow task                    | `"*/30 * * * * *"`                |
| `config.services.audit.workers` | Number of worker processes | `auto` |
| `config.services.audit.threads` | Number of threads per worker | `32` |
| `config.services.audit.wsEnabled`                         | Enable audit WebSocket                            | `false`                           |
| `config.services.audit.user.keepFor`                      | Data retention period for user data           | `90d`                             |
| `config.services.indexer.timeout`                         | Indexer request timeout seconds                   | `60`                              |
| `config.services.indexer.maxBatchSize`                    | Indexer max batch size                            | `1000`                            |
| `config.services.docreader.enabled`                       | Enable docreader integration                      | `false`                           |
| `config.services.docreader.prefix`                        | Docreader path prefix                             | `drapi`                           |
| `config.services.docreader.url`                           | Docreader base URL                                | `""`                              |
| `config.services.faceapi.enabled`                         | Enable faceapi integration                        | `false`                           |
| `config.services.faceapi.mode`                            | Faceapi operation mode (used by IDV)              | `idv`                             |
| `config.services.faceapi.prefix`                          | Faceapi path prefix                               | `faceapi`                         |
| `config.services.faceapi.url`                             | Faceapi base URL                                  | `""`                              |
| `config.services.ip2location.enabled`                     | Enable IP to Location service                     | `false`                           |
| `config.services.ip2location.type`                        | IP to Location type                               | `regula`                          |
| `config.services.ip2location.regula.url`                  | IP to Location URL                                | `https://lic.regulaforensics.com` |
| `config.services.ip2location.regula.timeout`              | IP to Location timeout                            | `3`                               |
| `config.services.livekit.enabled`                         | Enable Livekit                                    | `false`                           |
| `config.services.livekit.url`                             | Livekit URL                                       | `https://livekit.example.com`     |
| `config.services.livekit.apiKey`                          | API key for Livekit (provide via env var)         | `null`                            |
| `config.services.livekit.apiSecret`                       | API secret for Livekit (provide via env var)      | `null`                            |
| `config.services.livekit.egress.enabled`                  | Enable Livekit Egress                             | `false`                           |
| |
| `config.mongo.url`                                        | Mongo connection URL                              | `"mongodb://mongodb:27017/idv"`   |
| |
| `config.messageBroker.url`                                | Message broker URL                                | `"amqp://rabbitmq:5672/"`         |
| |
| `config.sentry.portal.enabled`                            | Enable Sentry integration                         | `false`                           |
| `config.sentry.portal.dsn`                                | Sentry DSN (provide via env var for security)     | `null`                            |
| `config.sentry.portal.environment`                        | Sentry environment name                           | `null`                            |
| |
| `config.storage.type`                                     | Storage type (`s3`\|`az`\|`gcs`)                  | `s3`                              |
| `config.storage.s3.bucket`                                | S3 bucket for all IDV data                        | `idv-bucket`                      |
| `config.storage.s3.endpoint`                              | S3 endpoint                                       | `""`                              |
| `config.storage.s3.accessKey`                             | S3 access key                                     | `null`                            |
| `config.storage.s3.accessSecret`                          | S3 access secret                                  | `null`                            |
| `config.storage.s3.region`                                | S3 region                                         | `"eu-central-1"`                  |
| `config.storage.s3.secure`                                | Use HTTPS for S3                                  | `true`                            |
| `config.storage.az.container`                             | Azure Blob container for all IDV data             | `null`                            |
| `config.storage.az.storageAccount`                        | Azure storage account                             | `""`                              |
| `config.storage.az.connectionString`                      | Azure connection string                           | `null`                            |
| `config.storage.gcs.bucket`                               | GCS bucket for all IDV data                       | `null`                            |
| `config.storage.gcs.gcsKeyJsonSecretName`                 | Secret name containing Google Service Account key | `null`                            |
| `config.storage.sessions.location.prefix`                 | Sessions prefix                                   | `"sessions"`                      |
| `config.storage.persons.location.prefix`                  | Persons prefix                                    | `"persons"`                       |
| `config.storage.workflows.location.prefix`                | Workflows prefix                                  | `"workflows"`                     |
| `config.storage.userFiles.location.prefix`                | User files prefix                                 | `"files"`                         |
| `config.storage.locales.location.prefix`                  | Locales prefix                                    | `"localization"`                  |
| `config.storage.assets.location.prefix`                   | Assets prefix                                     | `"assets"`                        |
| `config.storage.tempFiles.location.prefix`                | Temp files prefix                                 | `"files/tmp"`                     |
| `config.storage.banlists.location.prefix`                 | Banlists prefix                                   | `"banlist"`                       |
| `config.storage.thumbnails.location.prefix`               | Thumbnails prefix                                 | `"thumbnails"`                    |
| `config.storage.<entity>.location.bucket` / `.folder`     | **Deprecated (pre-3.10 per-entity layout).** Still honored when set; removed in IDV 5.0 | — |
| |
| `config.faceSearch.enabled`                               | Enable Face search                                | `false`                           |
| `config.faceSearch.limit`                                 | Max Face search results                           | `1000`                            |
| `config.faceSearch.threshold`                             | Face match threshold                              | `0.75`                            |
| `config.faceSearch.database.type`                         | Face DB type                                      | `opensearch`                      |
| `config.faceSearch.database.opensearch.host`              | OpenSearch host                                   | `opensearch`                      |
| `config.faceSearch.database.opensearch.port`              | OpenSearch port                                   | `9200`                            |
| `config.faceSearch.database.opensearch.useSsl`            | Use SSL for OpenSearch                            | `false`                           |
| `config.faceSearch.database.opensearch.verifyCerts`       | Verify OpenSearch certs                           | `false`                           |
| `config.faceSearch.database.opensearch.username`          | OpenSearch username                               | `null`                            |
| `config.faceSearch.database.opensearch.password`          | OpenSearch password                               | `null`                            |
| `config.faceSearch.database.opensearch.dimension`         | Vector dimension                                  | `512`                             |
| `config.faceSearch.database.opensearch.method`            | Vector index method                               | `hnsw`                            |
| `config.faceSearch.database.opensearch.awsAuth.enabled`   | Enable AWS auth for OpenSearch                    | `false`                           |
| `config.faceSearch.database.opensearch.awsAuth.region`    | AWS auth region                                   | `null`                            |
| `config.faceSearch.database.opensearch.awsAuth.accessKey` | AWS auth access key                               | `null`                            |
| `config.faceSearch.database.opensearch.awsAuth.secretKey` | AWS auth secret key                               | `null`                            |
| |
| `config.textSearch.enabled`                               | Enable Text search                                | `false`                           |
| `config.textSearch.limit`                                 | Max Text search results                           | `1000`                            |
| `config.textSearch.database.type`                         | Text DB type                                      | `opensearch`                      |
| `config.textSearch.database.opensearch.host`              | OpenSearch host                                   | `opensearch`                      |
| `config.textSearch.database.opensearch.port`              | OpenSearch port                                   | `9200`                            |
| `config.textSearch.database.opensearch.useSsl`            | Use SSL for OpenSearch                            | `false`                           |
| `config.textSearch.database.opensearch.verifyCerts`       | Verify OpenSearch certs                           | `false`                           |
| `config.textSearch.database.opensearch.username`          | OpenSearch username                               | `null`                            |
| `config.textSearch.database.opensearch.password`          | OpenSearch password                               | `null`                            |
| `config.textSearch.database.opensearch.awsAuth.enabled`   | Enable AWS auth for OpenSearch                    | `false`                           |
| `config.textSearch.database.opensearch.awsAuth.region`    | AWS auth region                                   | `null`                            |
| `config.textSearch.database.opensearch.awsAuth.accessKey` | AWS auth access key                               | `null`                            |
| `config.textSearch.database.opensearch.awsAuth.secretKey` | AWS auth secret key                               | `null`                            |
| |
| `config.mobile`                                           | **Deprecated.** Mobile config                     | `{}`                              |
| |
| `config.smtp.enabled`                                     | **Deprecated.** Enable SMTP                       | `false`                           |
| `config.smtp.host`                                        | **Deprecated.** SMTP host                         | `""`                              |
| `config.smtp.port`                                        | **Deprecated.** SMTP port                         | `587`                             |
| `config.smtp.tls`                                         | **Deprecated.** Use TLS for SMTP                  | `true`                            |
| `config.smtp.username`                                    | **Deprecated.** SMTP username                     | `""`                              |
| `config.smtp.password`                                    | **Deprecated.** SMTP password                     | `""`                              |
| |
| `config.oauth2.enabled`                                   | **Deprecated.** Enable OAuth2                     | `false`                           |
| `config.oauth2.accessTokenTtl`                            | **Deprecated.** OAuth2 access token TTL           | `600`                             |
| `config.oauth2.refreshTokenTtl`                           | **Deprecated.** OAuth2 refresh token TTL          | `604800`                          |
| `config.oauth2.providers`                                 | **Deprecated.** OAuth2 providers list             | `[]`                              |
| `config.oauth2.providers.name`                            | **Deprecated.** OAuth2 provider name              | `null`                            |
| `config.oauth2.providers.clientId`                        | **Deprecated.** OAuth2 provider clientId          | `null`                            |
| `config.oauth2.providers.scope`                           | **Deprecated.** OAuth2 provider scope             | `null`                            |
| `config.oauth2.providers.secret`                          | **Deprecated.** OAuth2 provider secret            | `null`                            |
| `config.oauth2.providers.type`                            | **Deprecated.** OAuth2 provider type              | `null`                            |
| `config.oauth2.providers.defaultRoles`                    | **Deprecated.** Roles to be assigned to the user  | `null`                            |
| `config.oauth2.providers.defaultGroups`                   | **Deprecated.** Groups to be assigned to the user | `null`                            |
| `config.oauth2.providers.urls.jwk`                        | **Deprecated.** OAuth2 provider JWK URL           | `null`                            |
| `config.oauth2.providers.urls.authorize`                  | **Deprecated.** OAuth2 provider authorize URL     | `null`                            |
| `config.oauth2.providers.urls.token`                      | **Deprecated.** OAuth2 provider token URL         | `null`                            |
| `config.oauth2.providers.urls.refresh`                    | **Deprecated.** OAuth2 provider refresh URL       | `null`                            |
| `config.oauth2.providers.urls.revoke`                     | **Deprecated.** OAuth2 provider revoke URL        | `null`                            |
| |
| `config.saml.enabled`                                     | **Deprecated.** Enable SAML                       | `false`                           |
| `config.saml.providers`                                   | **Deprecated.** Identity providers list           | `[]`                              |
| `config.saml.providers.name`                              | **Deprecated.** Identity provider name            | `null`                            |
| `config.saml.providers.defaultRoles`                      | **Deprecated.** Roles to be assigned to the user  | `null`                            |
| `config.saml.providers.defaultGroups`                     | **Deprecated.** Groups to be assigned to the user | `null`                            |
| `config.saml.providers.entityId`                          | **Deprecated.** Identity provider entityId        | `null`                            |
| `config.saml.providers.ssoService.url`                    | **Deprecated.** Identity provider SSO service URL | `null`                            |
| `config.saml.providers.security.x509cert`                 | **Deprecated.** Identity provider x509 cert (base64 encoded) | `null`                 |
| `config.saml.providers.security.spPrivateKey`             | **Deprecated.** Service provider private key (base64 encoded) | `null`                |
| `config.saml.providers.security.spPublicCert`             | **Deprecated.** Service provider public cert (base64 encoded) | `null`                |
| |
| `config.logging.level`                                    | Logging level                                     | `INFO`                            |
| `config.logging.formatter`                                | Log formatter                                     | `"%(asctime)s.%(msecs)03d - %(name)s - %(levelname)s - %(message)s"` |
| `config.logging.console`                                  | Enable console logging                            | `true`                            |
| `config.logging.file`                                     | Enable file logging                               | `false`                           |
| `config.logging.path`                                     | Log directory path                                | `/var/log`                        |
| `config.logging.maxFileSize`                              | Max log file size (bytes)                         | `10485760`                        |
| `config.logging.filesCount`                               | Number of rotated log files                       | `10`                              |
| |
| `config.metrics.statsd.enabled`                           | Enable StatsD metrics                             | `false`                           |
| `config.metrics.statsd.host`                              | StatsD host                                       | `null`                            |
| `config.metrics.statsd.port`                              | StatsD port                                       | `9125`                            |
| `config.metrics.statsd.prefix`                            | StatsD metrics prefix                             | `idv`                             |
| |
| `config.deviceRegistration.enabled`                       | Enable device registration                        | `false`                           |
| |
| `config.rateLimit.enabled`                                | **Deprecated.** Enable built‑in rate limiter      | `true`                            |
| `config.rateLimit.profiles.s.window`                      | **Deprecated.** Window duration for small profile | `"1m"`                            |
| `config.rateLimit.profiles.s.limit`                       | **Deprecated.** Request limit for small profile   | `10`                              |
| `config.rateLimit.profiles.m.window`                      | **Deprecated.** Window duration for medium profile | `"1m"`                           |
| `config.rateLimit.profiles.m.limit`                       | **Deprecated.** Request limit for medium profile  | `100`                             |
| `config.rateLimit.profiles.l.window`                      | **Deprecated.** Window duration for large profile | `"1m"`                            |
| `config.rateLimit.profiles.l.limit`                       | **Deprecated.** Request limit for large profile   | `1000`                            |
| `config.authorizedKeys.enabled`                           | Enable authorized keys support                    | `false`                           |
| |
| `env`                                                     | Environment variables list                        | `[]`                              |
| `ingress.enabled`                                         | Enable Ingress                                    | `false`                           |
| `ingress.annotations`                                     | Ingress annotations                               | `{}`                              |
| `ingress.hosts`                                           | Ingress hosts                                     | `[]`                              |
| `ingress.paths`                                           | Ingress paths                                     | `[]`                              |
| `ingress.pathType`                                        | Ingress path type                                 | `Prefix`                          |
| `ingress.tls`                                             | Ingress TLS entries                               | `[]`                              |
| |
| `route.main.enabled`       | Enables or disables creation of the Gateway API route                                      | `false`                                        |
| `route.main.apiVersion`    | API version of the Gateway API Route resource (e.g., gateway.networking.k8s.io/v1)         | `gateway.networking.k8s.io/v1`                 |
| `route.main.kind`          | Type of Gateway API Route. Options: GRPCRoute, HTTPRoute, TCPRoute, TLSRoute, UDPRoute     | `HTTPRoute`                                    |
| `route.main.annotations`   | Annotations to add to the Route resource                                                   | `{}`                                           |
| `route.main.labels`        | Labels to add to the Route resource                                                        | `{}`                                           |
| `route.main.hostnames`     | List of hostnames that the Route should match                                              | `[]`                                           |
| `route.main.parentRefs`    | List of parent references (e.g., Gateways) that this Route attaches to                     | `[]`                                           |
| `route.main.httpsRedirect` | Enables HTTPS redirect. Should only be enabled on an HTTP listener to avoid redirect loops | `false`                                        |
| `route.main.matches`       | List of match rules for the Route                                                          | `[{ path: { type: PathPrefix, value: "/" } }]` |
| |
| `networkPolicy.enabled`                                   | Enable NetworkPolicy                              | `false`                           |
| `networkPolicy.annotations`                               | NetworkPolicy annotations                         | `{}`                              |
| `networkPolicy.ingress`                                   | Set NetworkPolicy Ingress rules                   | `{}`                              |
| `networkPolicy.egress`                                    | Set NetworkPolicy Egress rules                    | `{}`                              |
| `serviceAccount.create`                                   | Create service account                            | `true`                            |
| `serviceAccount.annotations`                              | Service account annotations                       | `{}`                              |
| `serviceAccount.name`                                     | Service account name override                     | `""`                              |
| `rbac.create`                                             | Create Role and RoleBinding                       | `false`                           |
| `rbac.annotations`                                        | Role and RoleBinding annotations                  | `{}`                              |
| `rbac.useExistingRole`                                    | Existing Role name to use                         | `""`                              |
| `rbac.extraRoleRules`                                     | Extra rules for Role                              | `[]`                              |


> [!NOTE]
> The subcharts are used for the demonstration and Dev/Test purposes.
> We strongly recommend deploying separate installations of the required resources in Production.

## In-cluster TLS (trusted CA bundle)

When IDV connects to its backends (MongoDB, S3/object storage, OpenSearch, RabbitMQ) over TLS
signed by an internal/private CA, IDV must trust that CA. Rather than rebuilding the image, set
`tls.trustedCABundle.configMapName` to a ConfigMap containing a PEM CA bundle (for example one
produced by [cert-manager trust-manager](https://cert-manager.io/docs/trust/trust-manager/),
combining your private CA with the public CAs). For **all** IDV deployments the chart then:

- mounts the bundle as a directory at `tls.trustedCABundle.mountPath` (use this path for clients
  that take an explicit CA file, e.g. a MongoDB URL `…&tls=true&tlsCAFile=/etc/regula/tls/ca-bundle.pem`);
- overlays the bundle onto the image's CA store file(s) in `tls.trustedCABundle.caStorePaths`
  (by default the `botocore`, `certifi` and system stores — covering boto3/S3, opensearch-py and
  py-amqp/pymongo respectively); and
- sets `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, and `AWS_CA_BUNDLE` environment variables as an
  additional layer of coverage.

```yaml
tls:
  trustedCABundle:
    configMapName: my-ca-bundle   # ConfigMap with key `ca-bundle.pem`
```

The feature is disabled by default (`configMapName: ""`) and changes nothing in existing releases.
`caStorePaths` defaults target the idv-coordinator image; update when the image changes Python
version. For in-cluster TLS to RabbitMQ, set the broker URL scheme to `amqps://`; for OpenSearch
set `config.faceSearch.database.opensearch.verifyCerts: true` (and the same for `textSearch`).

## Subchart Parameters

Each switch also **overrides the matching `config` settings** you supplied. If a connection setting
seems to be ignored, check these first.

| Parameter             | Description                                                                             | Default |
|-----------------------|------------------------------------------------------------------------------------------|---------|
| `mongodb.enabled`     | Deploy MongoDB subchart. Overrides `config.mongo.url`                                    | `false` |
| `rabbitmq.enabled`    | Deploy RabbitMQ subchart. Overrides `config.messageBroker.url`                           | `false` |
| `minio.enabled`       | Deploy MinIO subchart. Overrides all of `config.storage.s3.*`                            | `false` |
| `minio.auth.rootUser` | MinIO root user. Also used as the S3 access key                                          | `user`  |
| `minio.auth.rootPassword` | MinIO root password. Also used as the S3 access secret                               | `password123` |
| `minio.console.enabled` | Deploy the MinIO web console as a separate Deployment                                  | `false` |
| `opensearch.enabled`  | Deploy OpenSearch subchart. Overrides all `faceSearch`/`textSearch` OpenSearch settings   | `false` |
| `statsd.enabled`      | Deploy Prometheus StatsD exporter. Overrides `config.metrics.statsd.host`/`port`          | `false` |

> **Upgrading to 1.16.0:** the MinIO subchart moved to
> [`bitnami/minio`](https://github.com/bitnami/charts/tree/main/bitnami/minio). Dev/Test only —
> installs pointing `config.storage.s3` at a real endpoint are unaffected.
>
> - Rename `minio.rootUser` / `minio.rootPassword` to `minio.auth.rootUser` /
>   `minio.auth.rootPassword`. The old keys are silently ignored.

## Deployed Components

Backoffice is exposed through the main ingress/route. The remaining services communicate internally through the message broker.

| Component | Deployment | Command | Scales out | Deployed when |
|---|---|---|---|---|
| Backoffice | `<release>-idv-backoffice` | `idv backoffice start` | Yes | Always |
| Workflow | `<release>-idv-workflow` | `idv workflow start` | Yes | Always |
| Scheduler | `<release>-idv-scheduler` | `idv scheduler start` | No | Always |
| Audit | `<release>-idv-audit` | `idv audit start` | No | Always |
| Indexer | `<release>-idv-indexer` | `idv indexer start` | No | `config.textSearch.enabled` or `config.faceSearch.enabled` |

The Indexer builds the search indexes and is deployed when either `config.textSearch.enabled` or
`config.faceSearch.enabled` is `true`.

## KEDA Autoscaling

KEDA (Kubernetes Event-driven Autoscaling) can be used to automatically scale the IDV deployment based on external metrics or events.

### Prerequisites

- KEDA operator installed in your cluster
- Authentication secret for your scaling trigger (if required)
