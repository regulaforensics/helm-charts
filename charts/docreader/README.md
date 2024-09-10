# Docreader Helm Chart

Fast and accurate data extraction from identity documents. On-premise and cloud integration.

## Add Chart

First of all, you need to add the `regulaforensics` chart:

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

See the [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.

## Prerequisites
> [!NOTE]
> - At least 2 GB of RAM available on your cluster per pod's worker
> - Helm >=3.10
> - PV provisioner support in the underlying infrastructure (essential for storing logs)
> - Kubernetes version >=1.23-0

## Installing the Chart

### Licensing

To install the chart, you need to obtain the `regula.license` file (at the [Client Portal](https://client.regulaforensics.com/), for example) and then create a Kubernetes Secret from that license file:

```console
kubectl create secret generic docreader-license --from-file=regula.license
```

Note that the `regula.license` file should be located in the same folder where the `kubectl create secret` command is executed.

### API v1

To install the chart with the release name `my-release` and API v1 capabilities (default):

```console
helm install my-release regulaforensics/docreader --set licenseSecretName=docreader-license
```

### Session API

To install the chart with the release name `my-release` and Session API capabilities:

```console
helm install my-release regulaforensics/docreader \
    --set licenseSecretName=docreader-license \
    --set config.service.sessionApi.enabled=true \
    --set postgresql.enabled=true
```

### RFID PKD PA support

To install the chart with the release name `my-release` and RFID PKD PA capabilities:

```console
helm install my-release regulaforensics/docreader \
    --set licenseSecretName=docreader-license \
    --set config.sdk.rfid.enabled=true

export POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=docreader,app.kubernetes.io/instance=my-release" -o jsonpath="{.items[0].metadata.name}")

kubectl cp <PKD_PA_CERTIFICATES_PATH> ${POD_NAME}:/app/pkdPa/
```

An alternative to PVCs with ReadWriteMany access mode is to create a custom image based on regulaforensics/docreader. This image will include RFID PKD masterlists onboard at the default path `/app/pkdPa/`, thereby eliminating the need for PVCs with ReadWriteMany for container creation.

```console
helm install my-release regulaforensics/docreader \
    --set image.repository=<your own repository> \
    --set image.tag=<your image tag> \
    --set licenseSecretName=docreader-license \
    --set config.sdk.rfid.enabled=true
```

### Chip Verification

To install the chart with the release name `my-release` and Chip Verification capabilities:

```console
helm install my-release regulaforensics/docreader \
    --set licenseSecretName=docreader-license \
    --set config.sdk.rfid.enabled=true \
    --set config.sdk.rfid.chipVerification.enabled=true \
    --set postgresql.enabled=true

export POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=docreader,app.kubernetes.io/instance=my-release" -o jsonpath="{.items[0].metadata.name}")

kubectl cp <PKD_PA_CERTIFICATES_PATH> ${POD_NAME}:/app/pkdPa/
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
helm upgrade my-release regulaforensics/docreader
```

### Upgrading an existing Release to a new major version

A major chart version change (like v0.1.2 -> v1.0.0) indicates that there is an incompatible breaking change needing manual actions.

## Common parameters

| Parameter                                 | Description                                                                                   | Default                       |
|-------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------------|
| `replicas`                                | Number of nodes                                                                               | `1`                           |
| `image.repository`                        | Image repository                                                                              | `regulaforensics/docreader`   |
| `image.tag`                               | Overrides the Docreader image tag, whose default is the chart appVersion                      | `""`                          |
| `image.pullPolicy`                        | Image pull policy                                                                             | `IfNotPresent`                |
| `imagePullSecrets`                        | Image pull secrets                                                                            | `[]`                          |
| `nameOverride`                            | String to partially override common.names.fullname template (will maintain the release name)  | `""`                          |
| `fullnameOverride`                        | String to fully override common.names.fullname template                                       | `""`                          |
| `commonLabels`                            | Extra labels to apply to all resources                                                        | `{}`                          |
| `resources`                               | CPU/Memory resource requests/limits                                                           | `{}`                          |
| `securityContext`                         | Enable security context                                                                       | `{}`                          |
| `podSecurityContext`                      | Enable pod security context                                                                   | `{}`                          |
| `podSecurityContext.fsGroup`              | Group ID for the pod                                                                          | `0`                           |
| `podAnnotations`                          | Map of annotations to add to the pods                                                         | `{}`                          |
| `priorityClassName`                       | Priority Class to use for each pod                                                            | `""`                          |
| `terminationGracePeriodSeconds`           | Termination grace period to use for each pod                                                  | `nil`                         |
| `lifecycle`                               | `preStop` lifecycle hook to control the termination order                                     | `{}`                          |
| `nodeSelector`                            | Node labels for pods assignment                                                               | `{}`                          |
| `affinity`                                | Affinity for pods assignment                                                                  | `{}`                          |
| `tolerations`                             | Tolerations for pods assignment                                                               | `[]`                          |
| `topologySpreadConstraints`               | Topology Spread Constraints for pod assignment                                                | `[]`                          |
| `podDisruptionBudget.enabled`             | Enable Pod Disruption Budgets                                                                 | `false`                       |
| `podDisruptionBudget.config`              | Configure Pod Disruption Budgets                                                              | `maxUnavailable: 1`           |
| `env`                                     | Additional environment variables                                                              | `[]`                          |
| `extraVolumes`                            | Additional Docreader volumes                                                                  | `[]`                          |
| `extraVolumeMounts`                       | Additional Docreader volume mounts                                                            | `[]`                          |
| `service.type`                            | Kubernetes service type                                                                       | `ClusterIP`                   |
| `service.port`                            | Kubernetes port where service is exposed                                                      | `80`                          |
| `service.annotations`                     | Service annotations (can be templated)                                                        | `{}`                          |
| `service.loadBalancerIP`                  | IP address to assign to load balancer (if supported)                                          | `nil`                         |
| `service.loadBalancerSourceRanges`        | List of IP CIDRs allowed access to lb (if supported)                                          | `[]`                          |
| `ingress.enabled`                         | Enables Ingress                                                                               | `false`                       |
| `ingress.className`                       | Ingress Class Name                                                                            | `false`                       |
| `ingress.annotations`                     | Ingress annotations                                                                           | `{}`                          |
| `ingress.hosts`                           | Ingress hostnames                                                                             | `[]`                          |
| `ingress.tls`                             | Ingress TLS configuration                                                                     | `[]`                          |
| `serviceAccount.create`                   | Whether to create Service Account                                                             | `false`                       |
| `serviceAccount.name`                     | Service Account name                                                                          | `""`                          |
| `serviceAccount.annotations`              | Service Account annotations                                                                   | `{}`                          |
| `serviceMonitor.enabled`                  | Whether to create ServiceMonitor for Prometheus operator                                      | `false`                       |
| `serviceMonitor.namespace`                | ServiceMonitor namespace                                                                      | `""`                          |
| `serviceMonitor.interval`                 | ServiceMonitor interval                                                                       | `30s`                         |
| `serviceMonitor.scrapeTimeout`            | ServiceMonitor scrape timeout                                                                 | `10s`                         |
| `serviceMonitor.additionalLabels`         | Additional labels that can be used so ServiceMonitor will be discovered by Prometheus         | `{}`                          |
| `livenessProbe.enabled`                   | Enable livenessProbe                                                                          | `true`                        |
| `readinessProbe.enabled`                  | Enable readinessProbe                                                                         | `true`                        |
| `startupProbe.enabled`                    | Enable startupProbe                                                                           | `true`                        |
| `autoscaling.enabled`                     | Enable autoscaling                                                                            | `false`                       |
| `networkPolicy.enabled`                   | Enable NetworkPolicy                                                                          | `false`                       |
| `networkPolicy.annotations`               | NetworkPolicy annotations                                                                     | `{}`                          |
| `networkPolicy.ingress`                   | Set NetworkPolicy Ingress rules                                                               | `{}`                          |
| `networkPolicy.egress`                    | Set NetworkPolicy Egress rules                                                                | `{}`                          |
| `rbac.create`                             | Create Role and RoleBinding                                                                   | `false`                       |
| `rbac.annotations`                        | Role and RoleBinding annotations                                                              | `{}`                          |
| `rbac.useExistingRole`                    | Existing Role name to use                                                                     | `""`                          |
| `rbac.extraRoleRules`                     | Extra rules for Role                                                                          | `[]`                          |

## Application parameters

| Parameter                                                 | Description                                                                       | Default                                                       |
|-----------------------------------------------------------|-----------------------------------------------------------------------------------|---------------------------------------------------------------|
| `licenseSecretName`                                       | The name of an existing secret containing the regula.license file                 | `""`                                                          |
| `config.sdk.systemInfo.returnSystemInfo`                  | Whether to hide system info (/api/healthz response)                               | `true`                                                        |
| `config.sdk.rfid.enabled`                                 | Whether to enable RFID PKD PA mode                                                | `false`                                                       |
| `config.sdk.rfid.pkdPaPath`                               | RFID PKD PA certificates path                                                     | `"/app/pkdPa"`                                                |
| `config.sdk.rfid.pkdPaExistingClaim`                      | Name of the existing Persistent Volume Claim containing RFID PKD PA certificates  | `""`                                                          |
| `config.sdk.rfid.chipVerification.enabled`                | Whether to enable Chip Verification mode                                          | `false`                                                       |
| `config.sdk.rfid.paSensitiveCodes`                        | RFID PKD PA Sensitive Codes to use                                                | `[]`                                                          |
|                                                                                                                                                                                                               |
| `config.service.webServer.port`                           | Port server binding                                                               | `8080`                                                        |
| `config.service.webServer.workers`                        | Number of workers per pod                                                         | `1`                                                           |
| `config.service.webServer.timeout`                        | Number of seconds for the worker to process the request                           | `30`                                                          |
| `config.service.webServer.maxRequests`                    | The maximum number of requests a worker will process before restarting            | `0`                                                           |
| `config.service.webServer.maxRequestsJitter`              | The maximum jitter to add to the `maxRequests` setting                            | `0`                                                           |
| `config.service.webServer.gracefulTimeout`                | Timeout for graceful workers restart                                              | `30`                                                          |
| `config.service.webServer.keepalive`                      | The number of seconds to wait for requests on a Keep-Alive connection             | `0`                                                           |
| `config.service.webServer.workerConnections`              | The maximum number of simultaneous clients                                        | `1000`                                                        |
| `config.service.webServer.demoApp.enabled`                | Serve a demo web app                                                              | `true`                                                        |
| `config.service.webServer.demoApp.webComponent.enabled`   | Whether to enable Web Component                                                   | `false`                                                       |
| `config.service.webServer.cors.origins`                   | Origin, allowed to use API                                                        | `*`                                                           |
| `config.service.webServer.cors.headers`                   | Headers, allowed to read from the API                                             | `*`                                                           |
| `config.service.webServer.cors.methods`                   | Methods, allowed to invoke on the API                                             | `"POST,PUT,GET,DELETE,PATCH,HEAD,OPTIONS`                     |
| `config.service.webServer.logging.level`                  | Specify application logs level. Possible values: `ERROR`, `WARN`, `INFO`, `DEBUG` | `INFO`                                                        |
| `config.service.webServer.logging.formatter`              | Specify application logs format. Possible values: `text`, `json`                  | `text`                                                        |
| `config.service.webServer.logging.access.console`         | Whether to print access logs to a console                                         | `true`                                                        |
| `config.service.webServer.logging.access.path`            | Access logs file path                                                             | `logs/access/docreader-access.log`                            |
| `config.service.webServer.logging.app.console`            | Whether to print application logs to a console                                    | `true`                                                        |
| `config.service.webServer.logging.app.path`               | Application logs file path                                                        | `logs/app/docreader-app.log`                                  |
| `config.service.webServer.logging.access.format`          | Access logs format                                                                | `%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"` |
| `config.service.webServer.metrics.enabled`                | Whether to enable prometheus metrics endpoint                                     | `false`                                                       |
| `config.service.webServer.ssl.enabled`                    | Whether to enable SSL mode                                                        | `false`                                                       |
| `config.service.webServer.ssl.certificatesSecretName`     | The name of an existing secret containing the cert/key files reuired for HTTPS    | `""`                                                          |
| `config.service.webServer.ssl.tlsVersion`                 | Specifies the version of the TLS protocol. Possible values: `1.1`, `1.2`, `1.3`   | `1.2`                                                         |
|                                                                                                                                                                                                               |
| `config.service.storage.type`                             | Global storage type. Possible values: `fs`, `s3`, `gcs`, `az`                     | `fs`                                                          |
| `config.service.storage.s3.accessKey`                     | S3 Access Key                                                                     | `""`                                                          |
| `config.service.storage.s3.accessSecret`                  | S3 Secret Access Key                                                              | `""`                                                          |
| `config.service.storage.s3.region`                        | S3 region                                                                         | `"us-east-1"`                                                 |
| `config.service.storage.s3.secure`                        | Secure connection                                                                 | `"true"`                                                      |
| `config.service.storage.s3.endpointUrl`                   | Endpoint URL to the S3 compatible storage                                         | `"https://s3.amazonaws.com"`                                  |
| `config.service.storage.s3.awsCredentialsSecretName`      | Secret name containing AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY credentials        | `""`                                                          |
| `config.service.storage.gcs.gcsKeyJsonSecretName`         | Secret name containing Google Service Account key (json file)                     | `""`                                                          |
| `config.service.storage.az.storageAccount`                | Azure storage Account Name                                                        | `""`                                                          |
| `config.service.storage.az.connectionString`              | Azure storage Account connection string                                           | `""`                                                          |
| `config.service.storage.az.connectionStringSecretName`    | Secret name containing Azure storage Account connection string                    | `""`                                                          |
|                                                                                                                                                                                                               |
| `config.service.database.connectionString`                | Database connection string                                                        | `""`                                                          |
| `config.service.database.connectionStringSecretName`      | Secret name containing database connection string                                 | `""`                                                          |


## config.service.processing parameters

| Parameter                                                         | Description                                                                                   | Default                               |
|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|---------------------------------------|
| `config.service.processing.results.enabled`                       | Whether to enable processing                                                                  | `false`                               |
| `config.service.processing.results.ecdhSchema`                    | ECDH schema to use                                                                            | `prime256v1`                          |
| `config.service.processing.results.location.bucket`               | The processing results bucket name in case of `s3`/`gcs` storage type                         | `""`                                  |
| `config.service.processing.results.location.container`            | The processing results storage container name in case of `az` storage type                    | `""`                                  |
| `config.service.processing.results.location.folder`               | The processing results folder name in case of `fs` storage type                               | `"/app/docreader-processing/results"` |
| `config.service.processing.results.location.prefix`               | The processing results prefix path in the `bucket/container`                                  | `"results"`                           |
| `config.service.processing.results.persistence.enabled`           | Whether to enable processing results persistence (Applicable only for the `fs` storage type)  | `false`                               |
| `config.service.processing.results.persistence.accessMode`        | The processing results data Persistence access modes                                          | `ReadWriteMany`                       |
| `config.service.processing.results.persistence.size`              | The size of processing results data Persistent Volume storage Class                           | `10Gi`                                |
| `config.service.processing.results.persistence.storageClassName`  | The processing results data Persistent Volume storage Class                                   | `""`                                  |
| `config.service.processing.results.persistence.existingClaim`     | Name of the existing Persistent Volume Claim                                                  | `""`                                  |


## Session API parameters

| Parameter                                                             | Description                                                                                        | Default                                      |
|-----------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|----------------------------------------------|
| `config.service.sessionApi.enabled`                                   | Whether to enable Session API mode (default)                                                       | `false`                                      |
| `config.service.sessionApi.transactions.location.bucket`              | The Session API result logs bucket name in case of `s3`/`gcs` storage type                         | `""`                                         |
| `config.service.sessionApi.transactions.location.container`           | The Session API result logs storage container name in case of `az` storage type                    | `""`                                         |
| `config.service.sessionApi.transactions.location.folder`              | The Session API result logs folder name in case of `fs` storage type                               | `"/app/docreader-session-api/transactions"`  |
| `config.service.sessionApi.transactions.location.prefix`              | The Session API result logs prefix path in the `bucket/container`                                  | `"data"`                                     |
| `config.service.sessionApi.transactions.persistence.enabled`          | Whether to enable Session API result logs persistence (Applicable only for the `fs` storage type)  | `false`                                      |
| `config.service.sessionApi.transactions.persistence.accessMode`       | The Session API logs data Persistence access modes                                                 | `ReadWriteMany`                              |
| `config.service.sessionApi.transactions.persistence.size`             | The size of Session API logs data Persistent Volume storage Class                                  | `10Gi`                                       |
| `config.service.sessionApi.transactions.persistence.storageClassName` | The Session API logs data Persistent Volume storage Class                                          | `""`                                         |
| `config.service.sessionApi.transactions.persistence.existingClaim`    | Name of the existing Persistent Volume Claim                                                       | `""`                                         |


## SDK Error Logs parameters
| Parameter                                                 | Description                                                                             | Default                         |
|-----------------------------------------------------------|-----------------------------------------------------------------------------------------|---------------------------------|
| `config.service.sdkErrorLog.enabled`                      | Whether to enable SDK Error Log                                                         | `false`                         |
| `config.service.sdkErrorLog.location.folder`              | The SDK Error Log folder name in case of `fs` storage type                              | `/app/docreader-errors/sdk`     |
| `config.service.sdkErrorLog.location.bucket`              | The SDK Error Log bucket name in case of `s3`/`gcs` storage type                        | `docreader-errors`              |
| `config.service.sdkErrorLog.location.container`           | The SDK Error Log storage container name in case of `az` storage type                   | `docreader-errors`              |
| `config.service.sdkErrorLog.location.prefix`              | The SDK Error Log prefix path in the `bucket/container`                                 | `sdk`                           |
| `config.service.sdkErrorLog.persistence.enabled`          | Whether to enable SDK Error Log persistence (Applicable only for the `fs` storage type) | `false`                         |
| `config.service.sdkErrorLog.persistence.accessMode`       | The SDK Error Log data Persistence access mode                                          | `ReadWriteMany`                 |
| `config.service.sdkErrorLog.persistence.size`             | The size of SDK Error Log data Persistent Volume storage                                | `10Gi`                          |
| `config.service.sdkErrorLog.persistence.storageClassName` | The SDK Error Log data Persistent Volume storage Class Name                             | `""`                            |
| `config.service.sdkErrorLog.persistence.existingClaim`    | Name of the existing Persistent Volume Claim                                            | `""`                            |


> [!NOTE]
> The subcharts are used for the demonstration and Dev/Test purposes.
> We strongly recommend to deploying separate installations of the DB in Production.

> [!TIP]
> Configuration for postgresql subchart
> For the advanced PostgreSQL configuration please refer to the official documentation.
> ref: https://github.com/bitnami/charts/tree/main/bitnami/postgresql

## Subchart parameters

| Parameter                   | Description                             | Default                                                   |
|-----------------------------|-----------------------------------------|-----------------------------------------------------------|
| `postgresql.enabled`        | Whether to enable postgresql subchart   | `false` Required by Session API / Chip Verification mode  |
| `postgresql.auth.username`  | postgresql Username                     | `regula`                                                  |
| `postgresql.auth.password`  | postgresql Password                     | `Regulapasswd#1`                                          |
| `postgresql.auth.database`  | postgresql database                     | `regula_db`                                               |
