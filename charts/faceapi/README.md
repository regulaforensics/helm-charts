# Face-API Helm Chart

* Fast and accurate data extraction from identity documents. On-premise and cloud integration

## Get Repo Info

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-test
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Prerequisites

- At least 2 GB of RAM available on your cluster per pod's worker
- Helm 3
- PV provisioner support in the underlying infrastructure (essential for storing logs)

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release regulaforensics/face-api
```

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.


## Configuration

| Parameter                                 | Description                                   | Default                                                   |
|-------------------------------------------|-----------------------------------------------|-----------------------------------------------------------|
| `replicas`                                | Number of nodes                               | `1`                                                       |
| `image.repository`                        | Image repository                              | `regulaforensics/face-api`                                |
| `image.tag`                               | Overrides the Face-API image tag whose defaultis the chart appVersion    | ``                             |
| `image.pullPolicy`                        | Image pull policy                             | `IfNotPresent`                                            |
| `imagePullSecrets`                        | Image pull secrets                            | `[]`                                                      |
| `resources`                               | CPU/Memory resource requests/limits           | `{}`                                                      |
| `general.bind`                            | IpAddress:port server binding                 | `0.0.0.0:41101`                                            |
| `general.workers`                         | Number of workers per pod                     | `1`                                                       |
| `general.backlog`                         | Maximum number of requests in a queue awaiting processing | `15`                                          |
| `general.timeout`                         | Number of seconds for the worker to process the request   | `120`                                         |
| `general.demoSite`                        | Serve a demo web app                          | `true`                                                    |
| `general.licenseUrl`                      | URL to regula.license file for further download   | ``                                                    |
| `general.httpsProxy`                      | HTTP proxy, used to connect to the license service    | ``                                                |
| `general.returnSystemInfo`                | Return system information in the /api/* response  | `true`                                                |
| `licenseSecretName`                       | The name of an existing secret containing the regula.license file | ``                                    |
| `https.enabled`                           | Enables https server mode                     | `[]`                                                      |
| `https.certificatesSecretName`            | The name of an existing secret containing the cert/key files reuired for https | `` mandatory if **https.enabled**  is set    |
| `cors.origins`                            | Origin, allowed to use API                    | no default, that means the web browser will allow requests to the web server from the same domain only    |
| `cors.methods`                            | Methods, allowed to invoke on the API         | `"GET, HEAD, POST, OPTIONS, PUT, PATCH, DELETE"` |
| `cors.headers`                            | Headers, allowed to read from the API         | `*` Specify comma-separated values as a single string (ex. "content-type,date")   |
| `identification.enabled`                  | Whether to enable Identification mode         | `false`                                                   |
| `identification.milvusHost`               | Milvus Host Name                              | `autopopulated`                                           |
| `identification.milvusPort`               | Milvus Port                                   | `19530`                                                   |
| `liveness.enabled`                        | Whether to enable Liveness mode               | `false`                                                   |
| `liveness.hideMetadata`                   | Whether to hide processing data's metadata    | `false`                                                   |
| `storage.endpoint`                        | Enpoint to the S3 comaitable storage          | `autopopulated`                                           |
| `storage.accessKey`                       | S3 Access Key                                 | `minioadmin`                                              |
| `storage.secretKey`                       | S3 Secret Key                                 | `minioadmin`                                              |
| `storage.region`                          | Storage Region in case of Amazon S3 usage     | `us-east-1`                                               |
| `storage.personBucketName`                | Bucket name where persons images are stored   | `faceapi-person`                                          |
| `storage.sessionBucketName`               | Bucket name where session is stored           | `faceapi-session`                                         |
| `externalPostgreSQL`                      | Connection String to the Postgres database    | `none` Option 1. Required by Identification/Liveness      |
| `externalPostgreSQLSecret`                | Secret name of the Connection String          | `none` Option 2. Required by Identification/Liveness module. ex. `postgresql://user:pass@host:5432/database`  |
| `postgresql.enabled`                      | Whether to enable postgresql subchart         | `false` Option 3. Required by Identification/Liveness module  |
| `postgresql.postgresqlUsername`           | postgresql Username                           | `regula`                                                  |
| `postgresql.postgresqlPassword`           | postgresql Password                           | `Regulapasswd#1`                                          |
| `postgresql.postgresqlDatabase`           | postgresql Database                           | `regula_db`                                               |
| `milvus.enabled`                          | Whether to enable Milvus subchart             | `false` Required by Identification module                 |
| `milvus.cluster.enabled`                  | Whether to enable Milvus cluster mode         | `false` Required by Minio distributed mode                |
| `milvus.minio.enabled`                    | Whether to enable Minio subchart              | `true` Required by Milvus                                 |
| `milvus.minio.mode`                       | Minio mode                                    | `standalone`                                              |
| `milvus.minio.accessKey`                  | Minio Access Key                              | `minioadmin`                                              |
| `milvus.minio.secretKey`                  | Minio Secret Key                              | `minioadmin`                                              |
| `milvus.minio.persistence.size`           | Minio volume size                             | `10Gi`                                                    |
| `milvus.pulsar.enabled`                   | Whether to enable Pulsar                      | `false` Required by Minio distributed mode                |
| `milvus.externalS3.enabled`               | Whether to enable External S3 integration     | `false` Optional replacement for Minio                    |
| `milvus.externalS3.host`                  | External S3 host                              | `none`                                                    |
| `milvus.externalS3.port`                  | External S3 port                              | `none`                                                    |
| `milvus.externalS3.accessKey`             | External S3 Access Key                        | `none`                                                    |
| `milvus.externalS3.secretKey`             | External S3 Secret Key                        | `none`                                                    |
| `milvus.externalS3.useSSL`                | Whether to use ssl within External S3         | `false`                                                   |
| `milvus.externalS3.bucketName`            | External S3 bucket name                       | `none`                                                    |
| `milvus.externalS3.rootPath`              | External S3 root path                         | `none`                                                    |
| `logs.level`                              | Specify application logs level                | `info` Possible values: "error", "warn", "info", "debug"  |
| `logs.type.accessLog`                     | Whether to save access logs to a file         | `true`                                                    |
| `logs.type.appLog`                        | Whether to save application logs to a file    | `true`                                                    |
| `logs.type.processLog.enabled`            | Whether to save process logs to a file        | `true`                                                    |
| `logs.type.processLog.saveResult`         | Whether to save process result                | `true`                                                    |
| `logs.format`                             | Log format, Possible values: "text","json"    | `text`                                                    |
| `logs.persistence.enabled`                | Use persistent volume to store face-api logs data    | `false`                                            |
| `logs.persistence.accessMode`             | The Face-API logs data Persistence access modes  | `ReadWriteMany`                                        |
| `logs.persistence.size`                   | The size of Face-API logs data Persistent Volume Storage Class   | `10Gi`                                 |
| `logs.persistence.storageClassName`       | The Face-API logs data Persistent Volume Storage Class   | ``                                             |
| `logs.persistence.existingClaim`          | Use your own data Persistent Volume existing claim name   | ``                                            |
| `env`                                     | Additional environment variables              | `[]`                                                      |
| `extraVolumes`                            | Additional Face-API volumes                   | `[]`                                                      |
| `extraVolumeMounts`                       | Additional Face-API volume mounts             | `[]`                                                      |
| `service.type`                            | Kubernetes service type                       | `ClusterIP`                                               |
| `service.port`                            | Kubernetes port where service is exposed      | `80`                                                      |
| `service.annotations`                     | Service annotations (can be templated)        | `{}`                                                      |
| `service.loadBalancerIP`                  | IP address to assign to load balancer (if supported) | `nil`                                              |
| `service.loadBalancerSourceRanges`        | List of IP CIDRs allowed access to lb (if supported) | `[]`                                               |
| `ingress.enabled`                         | Enables Ingress                               | `false`                                                   |
| `ingress.className`                       | Ingress Class Name                            | `false`                                                   |
| `ingress.annotations`                     | Ingress annotations                           | `{}`                                                      |
| `ingress.labels`                          | Ingress labels                                | `{}`                                                      |
| `ingress.hosts`                           | Ingress hostnames                             | `[]`                                                      |
| `livenessProbe.enabled`                   | Enable livenessProbe                          | `true`                                                    |
| `readinessProbe.enabled`                  | Enable readinessProbe                         | `true`                                                    |
| `autoscaling.enabled`                     | Enable autoscaling                            | `false`                                                   |
