# Docreader Helm Chart

* Fast and accurate data extraction from identity documents. On-premise and cloud integration

## Get Repo Info

```console
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
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
helm install my-release regulaforensics/docreader
```

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.


## Configuration

| Parameter                                 | Description                                   | Default                                                 |
|-------------------------------------------|-----------------------------------------------|---------------------------------------------------------|
| `replicas`                                | Number of nodes                               | `1`                                                     |
| `image.repository`                        | Image repository                              | `regulaforensics/docreader`                             |
| `image.tag`                               | Overrides the Docreader image tag whose defaultis the chart appVersion    | ``                              |
| `image.pullPolicy`                        | Image pull policy                             | `IfNotPresent`                                          |
| `imagePullSecrets`                        | Image pull secrets                            | `[]`                                                    |
| `resources`                               | CPU/Memory resource requests/limits           | `{}`                                                    |
| `general.bind`                            | IpAddress:port server binding                 | `0.0.0.0:8080`                                          |
| `general.workers`                         | Number of workers per pod                     | `1`                                                     |
| `general.backlog`                         | Maximum number of requests in a queue awaiting processing | `15`                                        |
| `general.timeout`                         | Number of seconds for the worker to process the request   | `120`                                       |
| `general.demoSite`                        | Serve a demo web app                          | `true`                                                  |
| `general.licenseUrl`                      | URL to regula.license file for further download   | ``                                                  |
| `general.httpsProxy`                      | HTTP proxy, used to connect to the license service    | ``                                              |
| `licenseSecretName`                       | The name of an existing secret containing the regula.license file | ``                                  |
| `https.enabled`                           | Enables https server mode                     | `[]`                                                    |
| `https.certificatesSecretName`            | The name of an existing secret containing the cert/key files reuired for https | `` mandatory if **https.enabled**  is set    |
| `cors.origins`                            | Origin, allowed to use API                    | no default, that means the web browser will allow requests to the web server from the same domain only    |
| `cors.methods`                            | Methods, allowed to invoke on the API         | `"GET, HEAD, POST, OPTIONS, PUT, PATCH, DELETE"` |
| `cors.headers`                            | Headers, allowed to read from the API         | `*` Specify comma-separated values as a single string (ex. "content-type,date")   |
| `logs.level`                              | Specify application logs level                | `info` Possible values: "error", "warn", "info", "debug"|
| `logs.type.accessLog`                     | Whether to save access logs to a file         | `true`                                                  |
| `logs.type.appLog`                        | Whether to save application logs to a file    | `true`                                                  |
| `logs.type.processLog.enabled`            | Whether to save process logs to a file        | `true`                                                  |
| `logs.type.processLog.saveResult`         | Whether to save process result                | `true`                                                  |
| `logs.format`                             | Log format, Possible values: "text","json"    | `text`                                                  |
| `logs.persistence.enabled`                | Use persistent volume to store docreader logs data    | `false`                                         |
| `logs.persistence.accessMode`             | The Docreader logs data Persistence access modes  | `ReadWriteMany`                                     |
| `logs.persistence.size`                   | The size of Docreader logs data Persistent Volume Storage Class   | `10Gi`                              |
| `logs.persistence.storageClassName`       | The Docreader logs data Persistent Volume Storage Class   | ``                                          |
| `logs.persistence.existingClaim`          | Use your own data Persistent Volume existing claim name   | ``                                          |
| `rfidpkd.enabled`                         | Whether to enable RFID PA feature             | `false`                                                 |
| `rfidpkd.existingClaim`                   | Provide Persistent Volume existing claim name prepopulated with RFID PA masterlists | `` mandatory if **rfidpkd.enabled** is set   |
| `chipVerification.enabled`                | Whether to enable Chip verification feature   | `false`                                                 |
| `minio.enabled`                           | Whether to enable Minio (required for Chip verification) | `false`                                      |
| `minio.mode`                              | Minio mode                                    | `standalone`                                            |
| `minio.rootUser`                          | Minio Root User                               | `regula`                                                |
| `minio.rootPassword`                      | Minio Root Password                           | `Regulapasswd#1`                                        |
| `minio.buckets.name`                      | Minio bucket name                             | `chip-verification-data`                                |
| `minio.buckets.policy`                    | Minio bucket policy                           | `none`                                                  |
| `minio.persistence.size`                  | Minio Volume size                             | `10Gi`                                                  |
| `env`                                     | Additional environment variables              | `[]`                                                    |
| `extraVolumes`                            | Additional Docreader volumes                  | `[]`                                                    |
| `extraVolumeMounts`                       | Additional Docreader volume mounts            | `[]`                                                    |
| `service.type`                            | Kubernetes service type                       | `ClusterIP`                                             |
| `service.port`                            | Kubernetes port where service is exposed      | `80`                                                    |
| `service.annotations`                     | Service annotations (can be templated)        | `{}`                                                    |
| `service.loadBalancerIP`                  | IP address to assign to load balancer (if supported) | `nil`                                            |
| `service.loadBalancerSourceRanges`        | List of IP CIDRs allowed access to lb (if supported) | `[]`                                             |
| `ingress.enabled`                         | Enables Ingress                               | `false`                                                 |
| `ingress.className`                       | Ingress Class Name                            | `false`                                                 |
| `ingress.annotations`                     | Ingress annotations                           | `{}`                                                    |
| `ingress.labels`                          | Ingress labels                                | `{}`                                                    |
| `ingress.hosts`                           | Ingress hostnames                             | `[]`                                                    |
| `livenessProbe.enabled`                   | Enable livenessProbe                          | `true`                                                  |
| `readinessProbe.enabled`                  | Enable readinessProbe                         | `true`                                                  |
| `autoscaling.enabled`                     | Enable autoscaling                            | `false`                                                 |
