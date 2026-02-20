# Face-API Helm Chart

Regula Face SDK API is a powerful solution for digital identity verification. The available features are Face Detection, Face Comparison (aka Match), Face Identification (aka Search), and Liveness Assessment. On-premise and cloud integration available.

## Add Chart

First of all, you need to add the `regulaforensics` chart:

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

See the [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.

## Prerequisites

- At least 3 GB of RAM available on your cluster per pod's worker
- Helm 3
- PV provisioner support in the underlying infrastructure (essential for storing logs)
- Kubernetes version >=1.23-0

## Installing the Chart

### Licensing

To install the chart, you need to obtain the `regula.license` file (at the [Client Portal](https://client.regulaforensics.com/), for example) and then create a Kubernetes Secret from that license file:

```console
kubectl create secret generic face-api-license --from-file=regula.license
```

Note that the `regula.license` file should be located in the same folder where the `kubectl create secret` command is executed.

### Detect/Match

To install the chart with the release name `my-release` and Detect/Match capabilities (default):

```console
helm install my-release regulaforensics/faceapi --set licenseSecretName=face-api-license
```

### Liveness

To install the chart with the release name `my-release` and Liveness capabilities:

```console
helm install my-release regulaforensics/faceapi \
    --set licenseSecretName=faceapi-license \
    --set config.service.liveness.enabled=true \
    --set postgresql.enabled=true
```

### Search

To install the chart with the release name `my-release` and Search capabilities:

```console
helm install my-release regulaforensics/faceapi \
    --set licenseSecretName=faceapi-license \
    --set config.service.search.enabled=true \
    --set milvus.enabled=true \
    --set postgresql.enabled=true
```

### Liveness and Search

To install the chart with the release name `my-release` and Search capabilities:

```console
helm install my-release regulaforensics/faceapi \
    --set licenseSecretName=faceapi-license \
    --set config.service.liveness.enabled=true \
    --set config.service.search.enabled=true \
    --set milvus.enabled=true \
    --set postgresql.enabled=true
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.


## Common parameters

| Parameter                             | Description                                                                                   | Default                       |
|---------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------------|
| `replicas`                            | Number of nodes                                                                               | `1`                           |
| `image.repository`                    | Image repository                                                                              | `regulaforensics/face-api`    |
| `image.tag`                           | Overrides the Face-API image tag                                                              | `"8.1-cpu"`               |
| `image.pullPolicy`                    | Image pull policy                                                                             | `IfNotPresent`                |
| `imagePullSecrets`                    | Image pull secrets                                                                            | `[]`                          |
| `nameOverride`                        | String to partially override common.names.fullname template (will maintain the release name)  | `""`                          |
| `fullnameOverride`                    | String to fully override common.names.fullname template                                       | `""`                          |
| `commonLabels`                        | Extra labels to apply to all resources                                                        | `{}`                          |
| `enableComponentLabels`               | Enable use of "app.kubernetes.io/component" label to distinguish Pods of different components | `false`                       |
| `resources`                           | CPU/Memory resource requests/limits                                                           | `{}`                          |
| `securityContext`                     | Enable security context                                                                       | `{}`                          |
| `podSecurityContext`                  | Enable pod security context                                                                   | `{}`                          |
| `podSecurityContext.fsGroup`          | Group ID for the pod                                                                          | `0`                           |
| `podAnnotations`                      | Map of annotations to add to the pods                                                         | `{}`                          |
| `priorityClassName`                   | Priority Class to use for each pod                                                            | `""`                          |
| `terminationGracePeriodSeconds`       | Termination grace period to use for each pod                                                  | `nil`                         |
| `lifecycle`                           | `preStop` lifecycle hook to control the termination order                                     | `{}`                          |
| `nodeSelector`                        | Node labels for pods assignment                                                               | `{}`                          |
| `jobNodeSelector`                     | Node labels for database migration jobs in GKE Autopilot (excludes Accelerator nodes)         | `{}`                          |
| `affinity`                            | Affinity for pods assignment                                                                  | `{}`                          |
| `tolerations`                         | Tolerations for pods assignment                                                               | `[]`                          |
| `topologySpreadConstraints`           | Topology Spread Constraints for pod assignment                                                | `[]`                          |
| `podDisruptionBudget.enabled`         | Enable Pod Disruption Budgets                                                                 | `false`                       |
| `podDisruptionBudget.config`          | Configure Pod Disruption Budgets                                                              | `maxUnavailable: 1`           |
| `env`                                 | Additional environment variables                                                              | `[]`                          |
| `extraVolumes`                        | Additional Face-API volumes                                                                   | `[]`                          |
| `extraVolumeMounts`                   | Additional Face-API volume mounts                                                             | `[]`                          |
| `service.type`                        | Kubernetes service type                                                                       | `ClusterIP`                   |
| `service.port`                        | Kubernetes port where service is exposed                                                      | `80`                          |
| `service.annotations`                 | Service annotations (can be templated)                                                        | `{}`                          |
| `service.loadBalancerIP`              | IP address to assign to load balancer (if supported)                                          | `nil`                         |
| `service.loadBalancerSourceRanges`    | List of IP CIDRs allowed access to lb (if supported)                                          | `[]`                          |
| `ingress.enabled`                     | Enables Ingress                                                                               | `false`                       |
| `ingress.className`                   | Ingress Class Name                                                                            | `false`                       |
| `ingress.annotations`                 | Ingress annotations                                                                           | `{}`                          |
| `ingress.hosts`                       | Ingress hosts (supports both string list and host objects with individual paths)              | `[]`                          |
| `ingress.paths`                       | Ingress paths (supports both simple strings and objects with service/action routing)          | `[]`                          |
| `ingress.pathType`                    | Ingress path type (Prefix, Exact, ImplementationSpecific)                                     | `Prefix`                      |
| `ingress.tls`                         | Ingress TLS configuration                                                                     | `[]`                          |
| `route.main.enabled`                  | Enables or disables creation of the Gateway API route                                         | `false`                       |
| `route.main.apiVersion`               | API version of the Gateway API Route resource (e.g., gateway.networking.k8s.io/v1)            | `gateway.networking.k8s.io/v1`|
| `route.main.kind`                     | Type of Gateway API Route. Options: GRPCRoute, HTTPRoute, TCPRoute, TLSRoute, UDPRoute        | `HTTPRoute`                   |
| `route.main.annotations`              | Annotations to add to the Route resource                                                      | `{}`                          |
| `route.main.labels`                   | Labels to add to the Route resource                                                           | `{}`                          |
| `route.main.hostnames`                | List of hostnames that the Route should match                                                 | `[]`                          |
| `route.main.parentRefs`               | List of parent references (e.g., Gateways) that this Route attaches to                        | `[]`                          |
| `route.main.httpsRedirect`            | Enables HTTPS redirect. Should only be enabled on an HTTP listener to avoid redirect loops    | `false`                       |
| `route.main.matches`                  | List of match rules for the Route                                                             | `[{ path: { type: PathPrefix, value: "/" } }]` |
| `serviceAccount.create`               | Whether to create Service Account                                                             | `false`                       |
| `serviceAccount.name`                 | Service Account name                                                                          | `""`                          |
| `serviceAccount.annotations`          | Service Account annotations                                                                   | `{}`                          |
| `serviceMonitor.enabled`              | Whether to create ServiceMonitor for Prometheus operator                                      | `false`                       |
| `serviceMonitor.namespace`            | ServiceMonitor namespace                                                                      | `""`                          |
| `serviceMonitor.interval`             | ServiceMonitor interval                                                                       | `30s`                         |
| `serviceMonitor.scrapeTimeout`        | ServiceMonitor scrape timeout                                                                 | `10s`                         |
| `serviceMonitor.additionalLabels`     | Additional labels that can be used so ServiceMonitor will be discovered by Prometheus         | `{}`                          |
| `livenessProbe.enabled`               | Enable livenessProbe                                                                          | `true`                        |
| `readinessProbe.enabled`              | Enable readinessProbe                                                                         | `true`                        |
| `startupProbe.enabled`                | Enable startupProbe                                                                           | `true`                        |
| `autoscaling.enabled`                 | Enable autoscaling                                                                            | `false`                       |
| `autoscaling.keda.enabled`            | Enable KEDA autoscaling                                                                       | `false`                       |
| `networkPolicy.enabled`               | Enable NetworkPolicy                                                                          | `false`                       |
| `networkPolicy.annotations`           | NetworkPolicy annotations                                                                     | `{}`                          |
| `networkPolicy.ingress`               | Set NetworkPolicy Ingress rules                                                               | `{}`                          |
| `networkPolicy.egress`                | Set NetworkPolicy Egress rules                                                                | `{}`                          |
| `rbac.create`                         | Create Role and RoleBinding                                                                   | `false`                       |
| `rbac.annotations`                    | Role and RoleBinding annotations                                                              | `{}`                          |
| `rbac.useExistingRole`                | Existing Role name to use                                                                     | `""`                          |
| `rbac.extraRoleRules`                 | Extra rules for Role                                                                          | `[]`                          |

## KEDA Autoscaling

KEDA (Kubernetes Event-driven Autoscaling) can be used to automatically scale the Face-API deployment based on external metrics or events.

### Prerequisites

- KEDA operator installed in your cluster
- Authentication secret for your scaling trigger (if required)

### Configuration

To enable KEDA autoscaling:

```console
helm install my-release regulaforensics/faceapi \
    --set licenseSecretName=face-api-license \
    --set autoscaling.keda.enabled=true
## Ingress Configuration

The Ingress resource supports multiple flexible configuration formats for advanced routing capabilities:

### Format 1: Simple host list with global paths

Use this format when all hosts should expose the same paths:

```yaml
ingress:
  enabled: true
  hosts:
    - faceapi.example.com
    - api.example.com
  paths:
    - /
    - /api/v1
    - /health
  pathType: Prefix
```

### Format 2: Host objects with individual paths

Use this format when each host needs its own set of paths:

```yaml
ingress:
  enabled: true
  hosts:
    - host: faceapi.example.com
      paths:
        - /
        - /api/v1
    - host: api.example.com
      paths:
        - /api
        - /health
  pathType: Prefix
```

### Format 3: Advanced routing with service/action support

Use this format for advanced scenarios like AWS ALB with fixed responses or custom service routing:

```yaml
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/actions.metrics-block: '{"type":"fixed-response","fixedResponseConfig":{"statusCode":"403","contentType":"text/plain","messageBody":"Forbidden"}}'
  hosts:
    - host: faceapi.example.com
      paths:
        - /
        - path: /metrics
          action: metrics-block
  pathType: Prefix
```

## Application parameters

| Parameter                                                 | Description                                                                       | Default                                                       |
|-----------------------------------------------------------|-----------------------------------------------------------------------------------|---------------------------------------------------------------|
| `licenseSecretName`                                       | The name of an existing secret containing the regula.license file                 | `""`                                                          |
| `config.sdk.compare.limitPerImageTypes`                   | Limit per Image Type                                                              | `2`                                                           |
| `config.sdk.param`                                        | Configuration of SDK `param` capabilities                                         | `[]`                                                          |
| `config.sdk.detect`                                       | Configuration of SDK `detect` capabilities                                        | `[]`                                                          |
| `config.sdk.liveness`                                     | Configuration of SDK `liveness` capabilities                                      | `[]`                                                          |
|                                                                                                                                                                                                               |
| `config.service.webServer.port`                           | Port server binding                                                               | `41101`                                                       |
| `config.service.webServer.workers`                        | Number of workers per pod                                                         | `1`                                                           |
| `config.service.webServer.timeout`                        | Number of seconds for the worker to process the request                           | `30`                                                          |
| `config.service.webServer.demoApp.enabled`                | Serve a demo web app                                                              | `true`                                                        |
| `config.service.webServer.cors.origins`                   | Origin, allowed to use API                                                        | `*`                                                           |
| `config.service.webServer.cors.headers`                   | Headers, allowed to read from the API                                             | `*`                                                           |
| `config.service.webServer.cors.methods`                   | Methods, allowed to invoke on the API                                             | `"POST,PUT,GET,DELETE,PATCH,HEAD,OPTIONS`                     |
| `config.service.webServer.logging.level`                  | Specify application logs level. Possible values: `ERROR`, `WARN`, `INFO`, `DEBUG` | `INFO`                                                        |
| `config.service.webServer.logging.formatter`              | Specify application logs format. Possible values: `text`, `json`                  | `text`                                                        |
| `config.service.webServer.logging.access.console`         | Whether to print access logs to a console                                         | `true`                                                        |
| `config.service.webServer.logging.access.path`            | Access logs file path                                                             | `logs/access/facesdk-reader-access.log`                       |
| `config.service.webServer.logging.access.format`          | Access logs format                                                                | `%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"` |
| `config.service.webServer.logging.app.console`            | Whether to print application logs to a console                                    | `true`                                                        |
| `config.service.webServer.logging.app.path`               | Application logs file path                                                        | `logs/app/facesdk-reader-app.log`                             |
| `config.service.webServer.metrics.enabled`                | Whether to enable Prometheus metrics endpoint                                     | `false`                                                       |
| `config.service.webServer.ssl.enabled`                    | Whether to enable SSL mode                                                        | `false`                                                       |
| `config.service.webServer.ssl.certificatesSecretName`     | The name of an existing secret containing the cert/key files required for HTTPS   | `""`                                                          |
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
| `config.service.storage.az.connectionString`              | Azure Storage Account connection string                                           | `""`                                                          |
| `config.service.storage.az.connectionStringSecretName`    | Secret name containing Azure Storage Account connection string                    | `""`                                                          |
|                                                                                                                                                                                                               |
| `config.service.database.connectionString`                | Database connection string                                                        | `""`                                                          |
| `config.service.database.connectionStringSecretName`      | Secret name containing Database connection string                                 | `""`                                                          |
| `config.service.database.passwordlessAuth.enabled`        | Whether to enable DB passwordless auth                                            | `false`                                                       |
| `config.service.database.passwordlessAuth.type`           | Global DB passwordless auth type. Possible values: `az`                           | `az`                                                          |
| `config.service.database.passwordlessAuth.az.scope`       | Azure SQL Auth Scope                                                              | `"https://database.windows.net/.default"`                     |


## Detect/Match parameters

| Parameter                                                         | Description                                                                                           | Default                               |
|-------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|---------------------------------------|
| `config.service.detectMatch.enabled`                              | Whether to enable Detect/Match mode (default)                                                         | Always `true`                         |
| `config.service.detectMatch.results.audit`                        | Whether to enable Detect/Match result audit records                                                   | `false`                               |
| `config.service.detectMatch.results.location.bucket`              | The Detect/Match result logs bucket name in case of `s3`/`gcs` storage type                           | `""`                                  |
| `config.service.detectMatch.results.location.container`           | The Detect/Match result logs storage container name in case of `az` storage type                      | `""`                                  |
| `config.service.detectMatch.results.location.folder`              | The Detect/Match result logs folder name in case of `fs` storage type                                 | `"/app/faceapi-detect-match/results"` |
| `config.service.detectMatch.results.location.prefix`              | The Detect/Match result logs prefix path in the `bucket/container`                                    | `"results"`                           |
| `config.service.detectMatch.results.persistence.enabled`          | Whether to enable Detect/Match result logs persistence (Applicable only for the `fs` storage type)    | `false`                               |
| `config.service.detectMatch.results.persistence.accessMode`       | The Detect/Match logs data Persistence access modes                                                   | `ReadWriteMany`                       |
| `config.service.detectMatch.results.persistence.size`             | The size of Detect/Match logs data Persistent Volume Storage Class                                    | `10Gi`                                |
| `config.service.detectMatch.results.persistence.storageClassName` | The Detect/Match logs data Persistent Volume Storage Class                                            | `""`                                  |
| `config.service.detectMatch.results.persistence.existingClaim`    | Name of the existing Persistent Volume Claim                                                          | `""`                                  |


## Liveness parameters

| Parameter                                                          | Description                                                                                   | Default                               |
|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|---------------------------------------|
| `config.service.liveness.enabled`                                  | Whether to enable Liveness mode                                                               | `false`                               |
| `config.service.liveness.ecdhSchema`                               | ECDH schema to use                                                                            | `default`                             |
| `config.service.liveness.hideMetadata`                             | Whether to hide processing data's metadata                                                    | `false`                               |
| `config.service.liveness.consistency`                              | The consistency model `eventual/strong`                                                       | `eventual`                            |
| `config.service.liveness.exposeData`                               | (Optional) Whether to expose portrait/video metadata                                          | `[]`                                  |
| `config.service.liveness.config`                                   | (Optional) Client configuration block                                                         | `[]`                                  |
| `config.service.liveness.sessions.location.bucket`                 | The Liveness sessions bucket name in case of `s3`/`gcs` storage type                          | `""`                                  |
| `config.service.liveness.sessions.location.container`              | The Liveness sessions storage container name in case of `az` storage type                     | `""`                                  |
| `config.service.liveness.sessions.location.folder`                 | The Liveness sessions folder name in case of `fs` storage type                                | `"/app/faceapi-liveness/sessions"`    |
| `config.service.liveness.sessions.location.prefix`                 | The Liveness sessions prefix path in the `bucket/container`                                   | `"sessions"`                          |
| `config.service.liveness.sessions.persistence.enabled`             | Whether to enable Liveness sessions persistence (Applicable only for the `fs` storage type)   | `false`                               |
| `config.service.liveness.sessions.persistence.accessMode`          | The Liveness sessions data Persistence access modes                                           | `ReadWriteMany`                       |
| `config.service.liveness.sessions.persistence.size`                | The size of Liveness sessions data Persistent Volume Storage Class                            | `10Gi`                                |
| `config.service.liveness.sessions.persistence.storageClassName`    | The Liveness sessions data Persistent Volume Storage Class                                    | `""`                                  |
| `config.service.liveness.sessions.persistence.existingClaim`       | Name of the existing Persistent Volume Claim                                                  | `""`                                  |


## Search parameters

| Parameter                                                             | Description                                                                               | Default                               |
|-----------------------------------------------------------------------|-------------------------------------------------------------------------------------------|---------------------------------------|
| `config.service.search.enabled`                                       | Whether to enable Identification 1:N (aka Search) mode                                    | `false`                               |
| `config.service.search.persons.location.bucket`                       | The Search persons bucket name in case of `s3`/`gcs` storage type                         | `""`                                  |
| `config.service.search.persons.location.container`                    | The Search persons storage container name in case of `az` storage type                    | `""`                                  |
| `config.service.search.persons.location.folder`                       | The Search persons folder name in case of `fs` storage type                               | `"/app/faceapi-search/persons"`       |
| `config.service.search.persons.location.prefix`                       | The Search persons prefix path in the `bucket/container`                                  | `"persons"`                           |
| `config.service.search.persons.persistence.enabled`                   | Whether to enable Search persons persistence (Applicable only for the `fs` storage type)  | `false`                               |
| `config.service.search.persons.persistence.accessMode`                | The Search persons data Persistence access modes                                          | `ReadWriteMany`                       |
| `config.service.search.persons.persistence.size`                      | The size of Search persons data Persistent Volume Storage Class                           | `10Gi`                                |
| `config.service.search.persons.persistence.storageClassName`          | The Search persons data Persistent Volume Storage Class                                   | `""`                                  |
| `config.service.search.persons.persistence.existingClaim`             | Name of the existing Persistent Volume Claim                                              | `""`                                  |
| `config.service.search.results.location.bucket`                       | (Optional) The Search results bucket name in case of `s3`/`gcs` storage type              | `""`                                  |
| `config.service.search.results.location.container`                    | (Optional) The Search results storage container name in case of `az` storage type         | `""`                                  |
| `config.service.search.results.location.folder`                       | (Optional) The Search results folder name in case of `fs` storage type                    | `"/app/faceapi-search/search-results"`|
| `config.service.search.results.location.prefix`                       | (Optional) The Search results prefix path in the `bucket/container`                       | `"search-results"`                    |
| `config.service.search.threshold`                                     | Search similarity threshold                                                               | `1.0`                                 |
| `config.service.search.vectorDatabase.type`                           | Search VectorDatabase type (supported types: `milvus`/ `opensearch`/ `atlas`)             | `milvus`                              |
| `config.service.search.vectorDatabase.milvus.user`                    | Milvus user                                                                               | `""`                                  |
| `config.service.search.vectorDatabase.milvus.password`                | Milvus password                                                                           | `""`                                  |
| `config.service.search.vectorDatabase.milvus.token`                   | Milvus token                                                                              | `""`                                  |
| `config.service.search.vectorDatabase.milvus.endpoint`                | Milvus endpoint                                                                           | `"http://localhost:19530"`            |
| `config.service.search.vectorDatabase.milvus.consistency`             | Milvus [consistency level](https://milvus.io/docs/consistency.md)                         | `"Bounded"`                           |
| `config.service.search.vectorDatabase.milvus.reload`                  | Milvus reload                                                                             | `false`                               |
| `config.service.search.vectorDatabase.milvus.index.type`              | Milvus [index type](https://milvus.io/docs/index.md)                                      | `IVF_FLAT`                            |
| `config.service.search.vectorDatabase.milvus.index.params.nlist`      | Milvus nlist cluster units                                                                | `128`                                 |
| `config.service.search.vectorDatabase.milvus.search.type`             | Milvus search type. [Similarity metrics](https://milvus.io/docs/metric.md)                | `"L2"`                                |
| `config.service.search.vectorDatabase.milvus.search.params.nprobe`    | Milvus search parameters. nprobe. The number of cluster units to search                   | `5`                                   |
| `config.service.search.vectorDatabase.opensearch.host`                | OpenSearch host                                                                           | `"opensearch"`                        |
| `config.service.search.vectorDatabase.opensearch.port`                | OpenSearch port                                                                           | `9200`                                |
| `config.service.search.vectorDatabase.opensearch.useSsl`              | Use SSL                                                                                   | `false`                               |
| `config.service.search.vectorDatabase.opensearch.verifyCerts`         | Verify Certificates                                                                       | `false`                               |
| `config.service.search.vectorDatabase.opensearch.username`            | OpenSearch username                                                                       | `"admin"`                             |
| `config.service.search.vectorDatabase.opensearch.password`            | OpenSearch password                                                                       | `"admin"`                             |
| `config.service.search.vectorDatabase.opensearch.dimension`           | OpenSearch dimension                                                                      | `512`                                 |
| `config.service.search.vectorDatabase.opensearch.awsAuth.enabled`     | OpenSearch Use AWS Authentication                                                         | `false`                               |
| `config.service.search.vectorDatabase.opensearch.awsAuth.region`      | OpenSearch AWS region                                                                     | `null`                                |
| `config.service.search.vectorDatabase.opensearch.awsAuth.accessKey`   | OpenSearch AWS Access Key                                                                 | `null`                                |
| `config.service.search.vectorDatabase.opensearch.awsAuth.secretKey`   | OpenSearch AWS Secret Access Key                                                          | `null`                                |
| `config.service.search.vectorDatabase.atlas.connectionString`         | Atlas Database connection string                                                          | `""`                                  |


## HouseKeeper parameters

| Parameter                                     | Description                                                        | Default    |
|-----------------------------------------------|--------------------------------------------------------------------|------------|
| `config.service.houseKeeper.enabled`          | Whether to enable HouseKeeper                                      | `true`     |
| `config.service.houseKeeper.beatCadence`      | HouseKeeper beat cadence in seconds                                | `10`       |
| `config.service.houseKeeper.keepFor`          | Time for keeping houseKeeper statistics in the database in seconds | `14400`    |
| `config.service.houseKeeper.liveness.enabled` | Whether to enable clearing data for liveness                       | `false`    |
| `config.service.houseKeeper.liveness.keepFor` | Time for keeping data for liveness in seconds                      | `31536000` |
| `config.service.houseKeeper.search.enabled`   | Whether to enable clearing data for search                         | `false`    |
| `config.service.houseKeeper.search.keepFor`   | Time for keeping data for search in seconds                        | `31536000` |


> [!NOTE]
> The subcharts are used for the demonstration and Dev/Test purposes related to the `liveness` and `search` capabilities.
> We strongly recommend deploying separate installations of the VectorDatabase (search) and DB (liveness/search) in Production.

> [!TIP]
> Configuration for milvus subchart
> For the advanced Milvus configuration, refer to the official documentation.
> ref: https://github.com/zilliztech/milvus-helm/tree/master/charts/milvus

> [!TIP]
> Configuration for postgresql subchart
>For the advanced PostgreSQL configuration, refer to the official documentation.
> ref: https://github.com/bitnami/charts/tree/main/bitnami/postgresql

## Subchart parameters

| Parameter                   | Description                             | Default                                   |
|-----------------------------|-----------------------------------------|-------------------------------------------|
| `milvus.enabled`            | Whether to enable Milvus subchart       | `false` Required by Search mode           |
| `postgresql.enabled`        | Whether to enable postgresql subchart   | `false` Required by Liveness/Search mode  |
| `postgresql.auth.username`  | postgresql Username                     | `regula`                                  |
| `postgresql.auth.password`  | postgresql Password                     | `Regulapasswd#1`                          |
| `postgresql.auth.database`  | postgresql Database                     | `regula_db`                               |
