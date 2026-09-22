# Quickstart

This guide will help you get a working IDV Platform in about ten minutes, using a bundled database, message queue, and file
storage. This setup is intended for evaluation and smaller deployments rather than high production loads. 

> **For demos only.** The bundled dependencies use well-known passwords, store nothing safely, and
> the encryption key is the public default. Do not put real data in it. For anything real, use the
> [Production install](03-install-production.md).

## Prerequisites 

Make sure you have: 

- A Kubernetes cluster (1.23 or newer) and `kubectl` connected to it
- Helm 3.10 or newer
- The `regula.license` file from the [Client Portal](https://client.regulaforensics.com/)
- About 4 CPU cores and 8 GB free in the cluster

## 1. Add the chart repository

First, add the `regulaforensics` Helm chart repository: 

```bash
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

## 2. Create a namespace and add the license

Create the namespace where IDV will be installed, then add the license. The name inside the Secret must be exactly `regula.license`.

```bash
kubectl create namespace regula-idv

kubectl create secret generic idv-license \
  --namespace regula-idv \
  --from-file=regula.license=./regula.license
```

> **Note:** If your organization uses strict RBAC policies and you cannot create namespaces, request your Kubernetes administrator to provision the `regula-idv` namespace for you with appropriate deployment permissions.

## 3. Install

Install IDV into the `regula-idv` namespace created in the previous step. 

```bash
helm install idv regulaforensics/idv \
  --namespace regula-idv \
  --set licenseSecretName=idv-license \
  --set mongodb.enabled=true \
  --set rabbitmq.enabled=true \
  --set minio.enabled=true \
  --wait --timeout 10m
```
The `--set licenseSecretName=idv-license` option tells IDV to use the `idv-license` Kubernetes Secret created in the previous step.

The following options enable the dependencies bundled with the IDV chart:

- `--set mongodb.enabled=true` — installs MongoDB for database storage.
- `--set rabbitmq.enabled=true` — installs RabbitMQ for message queuing.
- `--set minio.enabled=true` — installs MinIO for file/object storage.

When these bundled dependencies (MongoDB/RabbitMQ/MinIO) are enabled, the chart configures IDV to use them automatically. You do not need to provide their addresses or passwords separately.

`idv` is the Helm release name. Using `idv` keeps the generated service names short, such as `idv-api`.

## 4. Check it started

```bash
kubectl get pods -n regula-idv
```

A healthy installation should show the IDV and bundled dependency pods in the Running state, for example:

```
idv-api-...              1/1  Running
idv-audit-...            1/1  Running
idv-scheduler-...        1/1  Running
idv-workflow-...         1/1  Running
mongodb-...              1/1  Running
idv-rabbitmq-0           1/1  Running
idv-minio-...            1/1  Running
idv-minio-post-job-...   0/1  Completed
```

`idv-minio-post-job` should show `Completed`. It runs once to prepare storage. There is no
`idv-indexer` pod by default. This is expected when search is not enabled.

If anything is not running as expected, see [Troubleshooting](08-troubleshooting.md)

## 5. Create your login

**A new installation has no user accounts**. Create the first administrator account:

```bash
kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create \
    --name regula-idv \
    --password '<YOUR_PASSWORD>' \
    --email '<YOUR_EMAIL>' \
    --roles admin
```

Replace `<YOUR_PASSWORD>` and `<YOUR_EMAIL>` with your desired credentials.

The command should confirm the created account:

```
User: regula-idv
        User ID: 6a8d73f54e4d7a8bc485207f
        Email: <YOUR_EMAIL>
        Roles: ['admin']
        Active: True
```

Keep the password in single quotes so characters like `@` are not misread by your shell.

## 6. Open the portal

```bash
kubectl port-forward -n regula-idv svc/idv-api 8080:80
```

Go to <http://127.0.0.1:8080> and sign in with the account you created above.

## What will not work yet

**Verifying documents or faces.** IDV is running, but the services that read documents and match
faces are separate and not installed. See [Integrations](04-integrations.md).

**Scanning with a phone.** This needs a real web address with HTTPS. The demo has neither, so QR
codes point nowhere and browsers block camera access. That is the
[Production install](03-install-production.md).

## Remove it

To remove IDV and bundled dependencies, run:

```bash
helm uninstall idv -n regula-idv
kubectl delete namespace regula-idv
```

Deleting the namespace also clears the storage used by the bundled dependencies.

## Next

- Install it properly → [Production install](03-install-production.md)
- Add document and face verification → [Integrations](04-integrations.md)
