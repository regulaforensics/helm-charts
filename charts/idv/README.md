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
| `api.autoscaling.keda.triggers`                           | KEDA triggers for API                             | `[]`                              |
| `api.autoscaling.keda.TriggerAuthentication`              | KEDA TriggerAuthentication for API                | `null`                            |
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
| `workflow.autoscaling.keda.triggers`                      | KEDA triggers for Workflow                        | `[]`                              |
| `workflow.autoscaling.keda.TriggerAuthentication`         | KEDA TriggerAuthentication for Workflow           | `null`                            |
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
| `config.services.scheduler.jobs.cleanSessions.cron`       | Cron for cleaning sessions                        | `"*/30 * * * * *"`                |
| `config.services.scheduler.jobs.cleanSessions.keepFor`    | Keep session data for                             | `"1d"`                            |
| `config.services.scheduler.jobs.expireDeviceLogs.cron`    | Cron for expiring device logs                     | `"* */5 * * *"`                   |
| `config.services.scheduler.jobs.expireDeviceLogs.keepFor` | Keep device logs for                              | `"30d"`                           |
| `config.services.scheduler.jobs.reloadLocales.cron`       | Cron for reloading locales                        | `"*/15 * * * * *"`                |
| `config.services.scheduler.jobs.cronWorkflow.cron`        | Cron for generic workflow task                    | `"*/30 * * * * *"`                |
| `config.services.audit.wsEnabled`                         | Enable audit WebSocket                            | `false`                           |
| `config.services.indexer.timeout`                         | Indexer request timeout seconds                   | `60`                              |
| `config.services.indexer.maxBatchSize`                    | Indexer max batch size                            | `1000`                            |
| `config.services.docreader.enabled`                       | Enable docreader integration                      | `false`                           |
| `config.services.docreader.prefix`                        | Docreader path prefix                             | `drapi`                           |
| `config.services.docreader.url`                           | Docreader base URL                                | `""`                              |
| `config.services.faceapi.enabled`                         | Enable faceapi integration                        | `false`                           |
| `config.services.faceapi.prefix`                          | Faceapi path prefix                               | `faceapi`                         |
| `config.services.faceapi.url`                             | Faceapi base URL                                  | `""`                              |
| |
| `config.mongo.url`                                        | Mongo connection URL                              | `"mongodb://mongodb:27017/idv"`   |
| |
| `config.messageBroker.url`                                | Message broker URL                                | `"amqp://rabbitmq:5672/"`         |
| |
| `config.storage.type`                                     | Storage type                                      | `s3`                              |
| `config.storage.s3.endpoint`                              | S3 endpoint                                       | `""`                              |
| `config.storage.s3.accessKey`                             | S3 access key                                     | `null`                            |
| `config.storage.s3.accessSecret`                          | S3 access secret                                  | `null`                            |
| `config.storage.s3.region`                                | S3 region                                         | `"eu-central-1"`                  |
| `config.storage.s3.secure`                                | Use HTTPS for S3                                  | `true`                            |
| `config.storage.sessions.location.bucket`                 | Sessions bucket                                   | `coordinator`                     |
| `config.storage.sessions.location.prefix`                 | Sessions prefix                                   | `"sessions"`                      |
| `config.storage.persons.location.bucket`                  | Persons bucket                                    | `coordinator`                     |
| `config.storage.persons.location.prefix`                  | Persons prefix                                    | `"persons"`                       |
| `config.storage.workflows.location.bucket`                | Workflows bucket                                  | `coordinator`                     |
| `config.storage.workflows.location.prefix`                | Workflows prefix                                  | `"workflows"`                     |
| `config.storage.userFiles.location.bucket`                | User files bucket                                 | `coordinator`                     |
| `config.storage.userFiles.location.prefix`                | User files prefix                                 | `"files"`                         |
| `config.storage.locales.location.bucket`                  | Locales bucket                                    | `coordinator`                     |
| `config.storage.locales.location.prefix`                  | Locales prefix                                    | `"localization"`                  |
| `config.storage.assets.location.bucket`                   | Assets bucket                                     | `coordinator`                     |
| `config.storage.assets.location.prefix`                   | Assets prefix                                     | `"assets"`                        |
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
| `config.ip2location.enabled`                              | Enable IP to Location service                     | `false`                           |
| `config.ip2location.type`                                 | IP to Location type                               | `regula`                          |
| `config.ip2location.regula.url`                           | IP to Location URL                                | `https://lic.regulaforensics.com` |
| `config.ip2location.regula.timeout`                       | IP to Location timeout                            | `3`                               |
| |
| `env`                                                     | Environment variables list                        | `[]`                              |
| `ingress.enabled`                                         | Enable Ingress                                    | `false`                           |
| `ingress.annotations`                                     | Ingress annotations                               | `{}`                              |
| `ingress.hosts`                                           | Ingress hosts                                     | `[]`                              |
| `ingress.paths`                                           | Ingress paths                                     | `[]`                              |
| `ingress.pathType`                                        | Ingress path type                                 | `Prefix`                          |
| `ingress.tls`                                             | Ingress TLS entries                               | `[]`                              |
| `serviceAccount.create`                                   | Create service account                            | `true`                            |
| `serviceAccount.annotations`                              | Service account annotations                       | `{}`                              |
| `serviceAccount.name`                                     | Service account name override                     | `""`                              |


> [!NOTE]
> The subcharts are used for the demonstration and Dev/Test purposes.
> We strongly recommend to deploying separate installations of required resources in Production.

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
