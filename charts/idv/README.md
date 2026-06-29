# IDV Helm Chart

Identity Verification Plantform. On-premise and cloud integration.

## Add Chart

First of all, you need to add the `regulaforensics` chart:

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

See the [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.

## Prerequisites
> [!NOTE]
> - Helm >=3.10
> - Kubernetes version >=1.23-0

## Installing the Chart

### Licensing

To install the chart, you need to obtain the `regula.license` file (at the [Client Portal](https://client.regulaforensics.com/), for example) and then create a Kubernetes Secret from that license file:

```console
kubectl create secret generic idv-license --from-file=regula.license=/path/to/file
```

Note that the `regula.license` file should be located in the same folder where the `kubectl create secret` command is executed.

### Set config Fernet Encryption Key

> [!WARNING]
>
> We strongly recommend that you DO NOT USE the default `config.fernetKey` in production.

An example fernetKey can be generated via python:
```bash
pip install cryptography
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

#### Option 1 - using the value

You may set the fernet encryption key using the `config.fernetKey` value.
```yaml
config:
  fernetKey: "tton53xJw0QV6vfaOTNRP_YGnPc76ZJkXFdVFZSnaKQ="
```

#### Option 2 - using a secret (recommended)

You may set the fernet encryption key from a Kubernetes Secret by referencing it with the `config.env` value.

For example, to use the `fernet-key` key from the existing Secret called `idv-fernet-key`:
```bash
pip install cryptography
export IDV_FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
kubectl create secret generic idv-fernet-key --from-literal=fernet-key=${IDV_FERNET_KEY}
```

```yaml
config:
  env:
    - name: IDV_CONFIG__FERNETKEY
      valueFrom:
        secretKeyRef:
          name: idv-fernet-key
          key: fernet-key
```

### Configure LiveKit (Optional)

To enable LiveKit integration for video/audio capabilities, you need to configure the LiveKit server details and credentials.

#### Creating a Secret for LiveKit Credentials

Since `apiKey` and `apiSecret` are sensitive values, it's recommended to store them in a Kubernetes Secret:

```bash
kubectl create secret generic idv-livekit \
  --from-literal=IDV_CONFIG__SERVICES__LIVEKIT__APIKEY=your-api-key \
  --from-literal=IDV_CONFIG__SERVICES__LIVEKIT__APISECRET=your-api-secret
```

#### Configuring LiveKit in values.yaml

```yaml
config:
  services:
    livekit:
      enabled: true
      url: https://livekit.your-domain.com
      egress:
        enabled: false

env:
  - name: IDV_CONFIG__SERVICES__LIVEKIT__APIKEY
    valueFrom:
      secretKeyRef:
        name: idv-livekit
        key: IDV_CONFIG__SERVICES__LIVEKIT__APIKEY
  - name: IDV_CONFIG__SERVICES__LIVEKIT__APISECRET
    valueFrom:
      secretKeyRef:
        name: idv-livekit
        key: IDV_CONFIG__SERVICES__LIVEKIT__APISECRET
```

### Configure Sentry (Optional)

To enable Sentry integration for error tracking and monitoring, you can configure the Sentry portal settings.

#### Configuring Sentry in values.yaml

```yaml
config:
  sentry:
    portal:
      enabled: true
      dsn: "https://your-sentry-key@o0000.ingest.sentry.io/project-id"
      environment: "production"
```

To use sensitive values like DSN from Kubernetes Secrets (recommended):

```bash
kubectl create secret generic idv-sentry \
  --from-literal=IDV_CONFIG__SENTRY__PORTAL__DSN=your-sentry-dsn
```

```yaml
config:
  sentry:
    portal:
      enabled: true
      dsn: null
      environment: "production"

env:
  - name: IDV_CONFIG__SENTRY__PORTAL__DSN
    valueFrom:
      secretKeyRef:
        name: idv-sentry
        key: IDV_CONFIG__SENTRY__PORTAL__DSN
```

### Installation

To install the chart with the release name `my-release`:

```console
helm install my-release regulaforensics/idv \
  --set licenseSecretName=idv-license \
  --set mongodb.enabled=true \
  --set rabbitmq.enabled=true \
  --set minio.enabled=true
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Upgrading the Chart

To upgrade the `my-release` deployment:

```console
helm upgrade my-release regulaforensics/idv
```

## Chart parameters

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
| `image.pullPolicy`                                        | Image pull policy                                 | `Always`                          |
| `image.tag`                                               | Image tag override                                | `""`                              |
| `imagePullSecrets`                                        | Secrets for private registries                    | `{}`                              |
| `licenseSecretName`                                       | Name of existing secret containing regula.license | `null`                            |
| `api.replicas`                                            | Number of API replicas                            | `1`                               |
| `api.nodeSelector`                                        | Node selector for API pods                        | `{}`                              |
| `api.tolerations`                                         | Tolerations for API pods                          | `[]`                              |
| `api.affinity`                                            | Affinity rules for API pods                       | `{}`                              |
| `api.resources`                                           | Resource requests/limits for API                  | `{}`                              |
| `api.topologySpreadConstraints`                           | Topology spread constraints for API               | `[]`                              |
| `api.terminationGracePeriodSeconds`                       | API pod termination grace period                  | `45`                              |
| `api.lifecycle`                                           | API pod lifecycle hooks                           | `{}`                              |
| `api.service.type`                                        | API service type                                  | `ClusterIP`                       |
| `api.service.port`                                        | API service port                                  | `80`                              |
| `api.service.annotations`                                 | API service annotations                           | `{}`                              |
| `api.service.loadBalancerSourceRanges`                    | LoadBalancer source ranges for API                | `[]`                              |
| `api.autoscaling.enabled`                                 | Enable API autoscaling                            | `false`                           |
| `api.autoscaling.minReplicas`                             | Minimum API replicas                              | `1`                               |
| `api.autoscaling.maxReplicas`                             | Maximum API replicas                              | `100`                             |
| `api.autoscaling.targetCPUUtilizationPercentage`          | Target CPU utilization percent                    | `80`                              |
| `api.autoscaling.targetMemoryUtilizationPercentage`       | Target memory utilization percent                 | `80`                              |
| `api.autoscaling.keda.enabled`                            | Enable KEDA for API                               | `false`                           |
| `api.autoscaling.keda.minReplicaCount`                    | KEDA minimum replica count for API                | `1`                               |
| `api.autoscaling.keda.maxReplicaCount`                    | KEDA maximum replica count for API                | `100`                             |
| `api.autoscaling.keda.cooldownPeriod`                     | KEDA cooldown period (seconds) for API            | `300`                             |
| `api.autoscaling.keda.pollingInterval`                    | KEDA polling interval (seconds) for API           | `30`                              |
| `api.autoscaling.keda.advanced.scaleUp.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling up | `180`                    |
| `api.autoscaling.keda.advanced.scaleDown.stabilizationWindowSeconds` | Seconds the HPA observes metric before scaling down | `300`                |
| `api.autoscaling.keda.triggers`                           | KEDA triggers for API                             | `[]`                              |
| `api.autoscaling.keda.TriggerAuthentication`              | KEDA TriggerAuthentication for API                | `null`                            |
| `api.autoscaling.keda.fallback`                           | KEDA fallback config when metrics unavailable     | `null`                            |
| `api.autoscaling.keda.fallback.failureThreshold`          | Errors before fallback activates                  | `3`                               |
| `api.autoscaling.keda.fallback.replicas`                  | Replica count during fallback                     | `1`                               |
| `api.podDisruptionBudget.enabled`                         | Enable PDB for API                                | `false`                           |
| `api.podDisruptionBudget.config.maxUnavailable`           | PDB maxUnavailable for API                        | `~`                               |
| `api.podDisruptionBudget.config.minAvailable`             | PDB minAvailable for API                          | `1`                               |
| `api.probes.livenessProbe.enabled`                        | Enable API liveness probe                         | `true`                            |
| `api.probes.livenessProbe.initialDelaySeconds`            | Liveness initial delay                            | `5`                               |
| `api.probes.livenessProbe.timeoutSeconds`                 | Liveness timeout                                  | `5`                               |
| `api.probes.livenessProbe.periodSeconds`                  | Liveness period                                   | `10`                              |
| `api.probes.livenessProbe.successThreshold`               | Liveness success threshold                        | `1`                               |
| `api.probes.livenessProbe.failureThreshold`               | Liveness failure threshold                        | `3`                               |
| `api.probes.readinessProbe.enabled`                       | Enable API readiness probe                        | `true`                            |
| `api.probes.readinessProbe.initialDelaySeconds`           | Readiness initial delay                           | `5`                               |
| `api.probes.readinessProbe.timeoutSeconds`                | Readiness timeout                                 | `5`                               |
| `api.probes.readinessProbe.periodSeconds`                 | Readiness period                                  | `10`                              |
| `api.probes.readinessProbe.successThreshold`              | Readiness success threshold                       | `1`                               |
| `api.probes.readinessProbe.failureThreshold`              | Readiness failure threshold                       | `3`                               |
| `api.probes.startupProbe.enabled`                         | Enable API startup probe                          | `false`                           |
| `api.probes.startupProbe.initialDelaySeconds`             | Startup initial delay                             | `20`                              |
| `api.probes.startupProbe.timeoutSeconds`                  | Startup timeout                                   | `5`                               |
| `api.probes.startupProbe.periodSeconds`                   | Startup period                                    | `10`                              |
| `api.probes.startupProbe.successThreshold`                | Startup success threshold                         | `1`                               |
| `api.probes.startupProbe.failureThreshold`                | Startup failure threshold                         | `3`                               |
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
| `config.baseUrl`                                          | Application base URL                              | `""`                              |
| `config.fernetKey`                                        | Fernet encryption key                             | `""`                              |
| `config.tenant`                                           | Tenant name/id used for named broker topics       | `null`                            |
| `config.identifier`                                       | Instance identifier                               | `null`                            |
| `config.basicAuth.enabled`                                | Enable basic authentication                       | `false`                           |
| `config.services.api.port`                                | Internal API port                                 | `8000`                            |
| `config.services.api.host`                                | API bind host                                     | `0.0.0.0`                         |
| `config.services.api.workers`                             | API worker count                                  | `auto`                            |
| `config.services.api.threads`                             | API threads count                                 | `auto`                            |
| `config.services.api.keepalive`                           | Keepalive seconds                                 | `120`                             |
| `config.services.api.timeout`                             | Request timeout seconds                           | `120`                             |
| `config.services.api.cors.enabled`                        | Enable CORS                                       | `false`                           |
| `config.services.api.cors.origins`                        | Allowed origins                                   | `"*"`                             |
| `config.services.api.cors.methods`                        | Allowed methods                                   | `"*"`                             |
| `config.services.api.cors.headers`                        | Allowed headers                                   | `"*"`                             |
| `config.services.api.cors.maxAge`                         | CORS max age seconds                              | `0`                               |
| `config.services.api.maxBodySize`                         | Max body size                                     | `64Mi`                            |
| `config.services.api.openapi`                             | Enable OpenAPI docs                               | `false`                           |
| `config.services.workflow.workers`                        | Workflow service workers                          | `auto`                            |
| `config.services.scheduler.jobs.reloadWorkflows.cron`     | Cron for reloading workflows                      | `"*/15 * * * * *"`                |
| `config.services.scheduler.jobs.expireSessions.cron`      | Cron for expiring sessions                        | `"*/10 * * * * *"`                |
| `config.services.scheduler.jobs.cleanSessions.cron`       | Cron for cleaning sessions                        | `null`                            |
| `config.services.scheduler.jobs.cleanSessions.keepFor`    | Keep session data for                             | `null`                            |
| `config.services.scheduler.jobs.expireDeviceLogs.cron`    | Cron for expiring device logs                     | `"* */5 * * *"`                   |
| `config.services.scheduler.jobs.expireDeviceLogs.keepFor` | Keep device logs for                              | `"30d"`                           |
| `config.services.scheduler.jobs.reloadLocales.cron`       | Cron for reloading locales                        | `"*/15 * * * * *"`                |
| `config.services.scheduler.jobs.cronWorkflow.cron`        | Cron for generic workflow task                    | `"*/30 * * * * *"`                |
| `config.services.audit.wsEnabled`                         | Enable audit WebSocket                            | `false`                           |
| `config.services.audit.user.keepFor`                      | Keep user data for specific time period           | `90d`                             |
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
| `config.storage.type`                                     | Storage type (s3|az|gcs)                          | `s3`                              |
| `config.storage.s3.endpoint`                              | S3 endpoint                                       | `""`                              |
| `config.storage.s3.accessKey`                             | S3 access key                                     | `null`                            |
| `config.storage.s3.accessSecret`                          | S3 access secret                                  | `null`                            |
| `config.storage.s3.region`                                | S3 region                                         | `"eu-central-1"`                  |
| `config.storage.s3.secure`                                | Use HTTPS for S3                                  | `true`                            |
| `config.storage.az.storageAccount`                        | Azure storage account                             | `""`                              |
| `config.storage.az.connectionString`                      | Azure connection string                           | `null`                            |
| `config.storage.gcs.gcsKeyJsonSecretName`                 | Secret name containing Google Service Account key | `null`                            |
| `config.storage.sessions.location.bucket`                 | Sessions bucket                                   | `idv-bucket`                      |
| `config.storage.sessions.location.prefix`                 | Sessions prefix                                   | `"sessions"`                      |
| `config.storage.persons.location.bucket`                  | Persons bucket                                    | `idv-bucket`                      |
| `config.storage.persons.location.prefix`                  | Persons prefix                                    | `"persons"`                       |
| `config.storage.workflows.location.bucket`                | Workflows bucket                                  | `idv-bucket`                      |
| `config.storage.workflows.location.prefix`                | Workflows prefix                                  | `"workflows"`                     |
| `config.storage.userFiles.location.bucket`                | User files bucket                                 | `idv-bucket`                      |
| `config.storage.userFiles.location.prefix`                | User files prefix                                 | `"files"`                         |
| `config.storage.locales.location.bucket`                  | Locales bucket                                    | `idv-bucket`                      |
| `config.storage.locales.location.prefix`                  | Locales prefix                                    | `"localization"`                  |
| `config.storage.assets.location.bucket`                   | Assets bucket                                     | `idv-bucket`                      |
| `config.storage.assets.location.prefix`                   | Assets prefix                                     | `"assets"`                        |
| `config.storage.tempFiles.location.bucket`                | Temp files bucket                                 | `idv-bucket`                      |
| `config.storage.tempFiles.location.prefix`                | Temp files prefix                                 | `"tmp"`                           |
| `config.storage.tempFiles.location.folder`                | Temp files folder                                 | `"files"`                         |
| `config.storage.banlists.location.bucket`                 | Banlists bucket                                   | `idv-bucket`                      |
| `config.storage.banlists.location.prefix`                 | Banlists prefix                                   | `"banlist"`                       |
| |
| `config.faceSearch.enabled`                               | Enable Face search                                | `false`                           |
| `config.faceSearch.limit`                                 | Max Face search results                           | `1000`                            |
| `config.faceSearch.threshold`                             | Face match threshold                              | `0.75`                            |
| `config.faceSearch.database.type`                         | Face DB type                                      | `opensearch`                      |
| `config.faceSearch.database.opensearch.host`              | OpenSearch host                                   | `opensearch`                      |
| `config.faceSearch.database.opensearch.port`              | OpenSearch port                                   | `9200`                            |
| `config.faceSearch.database.opensearch.useSsl`            | Use SSL for OpenSearch                            | `false`                           |
| `config.faceSearch.database.opensearch.verifyCerts`       | Verify OpenSearch certs                           | `false`                           |
| `config.faceSearch.database.opensearch.username`          | OpenSearch username                               | `admin`                           |
| `config.faceSearch.database.opensearch.password`          | OpenSearch password                               | `""`                              |
| `config.faceSearch.database.opensearch.dimension`         | Vector dimension                                  | `512`                             |
| `config.faceSearch.database.opensearch.indexName`         | Index name                                        | `hnsw`                            |
| `config.faceSearch.database.opensearch.awsAuth.enabled`   | Enable AWS auth for OpenSearch                    | `false`                           |
| `config.faceSearch.database.opensearch.awsAuth.region`    | AWS auth region                                   | `""`                              |
| `config.faceSearch.database.opensearch.awsAuth.accessKey` | AWS auth access key                               | `""`                              |
| `config.faceSearch.database.opensearch.awsAuth.secretKey` | AWS auth secret key                               | `""`                              |
| |
| `config.textSearch.enabled`                               | Enable Text search                                | `false`                           |
| `config.textSearch.limit`                                 | Max Text search results                           | `1000`                            |
| `config.textSearch.threshold`                             | Text match threshold                              | `0.75`                            |
| `config.textSearch.database.type`                         | Text DB type                                      | `opensearch`                      |
| `config.textSearch.database.opensearch.host`              | OpenSearch host                                   | `opensearch`                      |
| `config.textSearch.database.opensearch.port`              | OpenSearch port                                   | `9200`                            |
| `config.textSearch.database.opensearch.useSsl`            | Use SSL for OpenSearch                            | `false`                           |
| `config.textSearch.database.opensearch.verifyCerts`       | Verify OpenSearch certs                           | `false`                           |
| `config.textSearch.database.opensearch.username`          | OpenSearch username                               | `admin`                           |
| `config.textSearch.database.opensearch.password`          | OpenSearch password                               | `""`                              |
| `config.textSearch.database.opensearch.dimension`         | Vector dimension                                  | `512`                             |                           
| `config.textSearch.database.opensearch.indexName`         | Index name                                        | `hnsw`                            |
| `config.textSearch.database.opensearch.awsAuth.enabled`   | Enable AWS auth for OpenSearch                    | `false`                           |
| `config.textSearch.database.opensearch.awsAuth.region`    | AWS auth region                                   | `""`                              |
| `config.textSearch.database.opensearch.awsAuth.accessKey` | AWS auth access key                               | `""`                              |
| `config.textSearch.database.opensearch.awsAuth.secretKey` | AWS auth secret key                               | `""`                              |
| |
| `config.mobile`                                           | Mobile config                                     | `{}`                              |
| |
| `config.smtp.enabled`                                     | Enable SMTP                                       | `false`                           |
| `config.smtp.host`                                        | SMTP host                                         | `""`                              |
| `config.smtp.port`                                        | SMTP port                                         | `587`                             |
| `config.smtp.tls`                                         | Use TLS for SMTP                                  | `true`                            |
| `config.smtp.username`                                    | SMTP username                                     | `""`                              |
| `config.smtp.password`                                    | SMTP password                                     | `""`                              |
| |
| `config.oauth2.enabled`                                   | Enable OAuth2                                     | `false`                           |
| `config.oauth2.accessTokenTtl`                            | OAuth2 access token TTL                           | `600`                             |
| `config.oauth2.refreshTokenTtl`                           | OAuth2 refresh token TTL                          | `604800`                          |
| `config.oauth2.providers`                                 | OAuth2 providers list                             | `[]`                              |
| `config.oauth2.providers.name`                            | OAuth2 provider name                              | `null`                            |
| `config.oauth2.providers.clientId`                        | OAuth2 provider clientId                          | `null`                            |
| `config.oauth2.providers.scope`                           | OAuth2 provider scope                             | `null`                            |
| `config.oauth2.providers.secret`                          | OAuth2 provider secret                            | `null`                            |
| `config.oauth2.providers.type`                            | OAuth2 provider type                              | `null`                            |
| `config.oauth2.providers.defaultRoles`                    | Roles to be assigned to the user                  | `null`                            |
| `config.oauth2.providers.defaultGroups`                   | Groups to be assigned to the user                 | `null`                            |
| `config.oauth2.providers.urls.jwk`                        | OAuth2 provider JWK URL                           | `null`                            |
| `config.oauth2.providers.urls.authorize`                  | OAuth2 provider authorize URL                     | `null`                            |
| `config.oauth2.providers.urls.token`                      | OAuth2 provider token URL                         | `null`                            |
| `config.oauth2.providers.urls.refresh`                    | OAuth2 provider refresh URL                       | `null`                            |
| `config.oauth2.providers.urls.revoke`                     | OAuth2 provider revoke URL                        | `null`                            |
| |
| `config.saml.enabled`                                     | Enable SAML                                       | `false`                           |
| `config.saml.providers`                                   | Identity providers list                           | `[]`                              |
| `config.saml.providers.name`                              | Identity provider name                            | `null`                            |
| `config.saml.providers.defaultRoles`                      | Roles to be assigned to the user                  | `null`                            |
| `config.saml.providers.defaultGroups`                     | Groups to be assigned to the user                 | `null`                            |
| `config.saml.providers.entityId`                          | Identity provider entityId                        | `null`                            |
| `config.saml.providers.ssoService.url`                    | Identity provider SSO service URL                 | `null`                            |
| `config.saml.providers.security.x509cert`                 | Identity provider x509 cert (base64 encoded)      | `null`                            |
| `config.saml.providers.security.spPrivateKey`             | Service provider private key (base64 encoded)     | `null`                            |
| `config.saml.providers.security.spPublicCert`             | Service provider public cert (base64 encoded)     | `null`                            |
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
| `config.rateLimit.enabled`                                | Enable built‑in rate limiter                      | `true`                            |
| `config.rateLimit.profiles.s.window`                      | Window duration for small profile                 | `"1m"`                            |
| `config.rateLimit.profiles.s.limit`                       | Request limit for small profile                   | `10`                              |
| `config.rateLimit.profiles.m.window`                      | Window duration for medium profile                | `"1m"`                            |
| `config.rateLimit.profiles.m.limit`                       | Request limit for medium profile                  | `100`                             |
| `config.rateLimit.profiles.l.window`                      | Window duration for large profile                 | `"1m"`                            |
| `config.rateLimit.profiles.l.limit`                       | Request limit for large profile                   | `1000`                            |
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
> We strongly recommend to deploying separate installations of required resources in Production.

## In-cluster TLS (trusted CA bundle)

When IDV connects to its backends (MongoDB, S3/object storage, OpenSearch, RabbitMQ) over TLS
signed by an internal/private CA, IDV must trust that CA. Rather than rebuilding the image, set
`tls.trustedCABundle.configMapName` to a ConfigMap containing a PEM CA bundle (for example one
produced by [cert-manager trust-manager](https://cert-manager.io/docs/trust/trust-manager/),
combining your private CA with the public CAs). For **all five** IDV deployments the chart then:

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

## Subchart parameters

| Parameter             | Description                                 | Default |
|-----------------------|---------------------------------------------|---------|
| `statsd.enabled`      | Enable Prometheus StatsD exporter subchart  | `false` |
| `mongodb.enabled`     | Enable MongoDB subchart                     | `false` |
| `rabbitmq.enabled`    | Enable RabbitMQ subchart                    | `false` |
| `minio.enabled`       | Enable Minio subchart                       | `false` |
| `opensearch.enabled`  | Enable OpenSearch subchart                  | `false` |


## KEDA Autoscaling

KEDA (Kubernetes Event-driven Autoscaling) can be used to automatically scale the IDV deployment based on external metrics or events.

### Prerequisites

- KEDA operator installed in your cluster
- Authentication secret for your scaling trigger (if required)
