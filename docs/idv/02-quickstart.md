# Quickstart

This guide will help you get a working IDV Platform in about ten minutes, using a bundled database, message queue, and file
storage. This setup is intended for evaluation only, not production workloads.

> **Warning**
> **For demos only.** 
> The bundled dependencies use default credentials, and the default encryption key is publicly known. Do not use this setup with real or sensitive data.
> For a production deployment, see [Production installation](./03-install-production.md).

> **Note:** In version 3.10, the `api` component was renamed to `backoffice`. The `api` component name remains supported for backward compatibility in version 3.10, but we recommend updating your configuration to use `backoffice`.
>
> During the upgrade, `backoffice` is unavailable for about 20 seconds. Plan the upgrade for a maintenance window.

Main steps:

- [Prerequisites](#prerequisites)
- [1. Add the Helm Chart Repository](#1-add-the-helm-chart-repository)
- [2. Create the Namespace and Add the License](#2-create-the-namespace-and-add-the-license)
- [3. Install IDV](#3-install-idv)
- [4. Verify the Installation](#4-verify-the-installation)
- [5. Create an Administrator Account](#5-create-an-administrator-account)
- [6. Open the Portal](#6-open-the-portal)
- [Setup Limitations](#setup-limitations)
- [Uninstall IDV](#uninstall-idv)

## Prerequisites

Make sure you have:

- A Kubernetes cluster version 1.23 or newer with `kubectl` connected to it
- Helm 3.10 or newer
- The `regula.license` file from the <a href="https://client.regulaforensics.com/" target="_blank" rel="noopener noreferrer">Client Portal</a>
- About 4 CPU cores and 8 GB of RAM in the cluster
- At least one x86-64 (amd64) node: the bundled MongoDB image is not available for ARM (arm64)

## 1. Add the Helm Chart Repository

Add the `regulaforensics` Helm chart repository:

```bash
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

## 2. Create the Namespace and Add the License

Create the namespace where IDV will be installed:

```bash
kubectl create namespace regula-idv
```

Then create a Kubernetes Secret containing your license:

```bash
kubectl create secret generic idv-license \
  --namespace regula-idv \
  --from-file=regula.license=./regula.license
```

The key inside the Secret must be exactly `regula.license`.

> **Note**
>
> If your organization uses strict RBAC policies and you cannot create namespaces, ask your Kubernetes administrator to create the `regula-idv` namespace and grant you the required deployment permissions.

## 3. Install IDV

Install IDV in the `regula-idv` namespace:

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
- `--set minio.enabled=true` — installs MinIO for file and object storage.

When you enable the bundled MongoDB, RabbitMQ, and MinIO dependencies, the chart automatically configures IDV to use them. You do not need to provide their addresses or passwords separately.

`idv` is the Helm release name. Using `idv` keeps generated service names short, such as `idv-backoffice`.

## 4. Verify the Installation

Check the pods in the `regula-idv` namespace:

```bash
kubectl get pods -n regula-idv
```

A healthy installation should show the IDV and bundled dependency pods in the `Running` state. For example:

```text
idv-backoffice-...       1/1  Running
idv-audit-...            1/1  Running
idv-scheduler-...        1/1  Running
idv-workflow-...         1/1  Running
mongodb-...              1/1  Running
idv-rabbitmq-0           1/1  Running
idv-minio-...            1/1  Running
```

Each IDV pod starts with an `init-minio-bucket` init container that creates the storage bucket in MinIO, so the pods briefly show `Init:0/1` before `Running`.

There is no `idv-indexer` pod by default. This is expected when search is not enabled.

If anything is not running as expected, see [Troubleshooting](./08-troubleshooting.md).

## 5. Create an Administrator Account

A new installation has no user accounts. Create the first administrator account:

```bash
kubectl exec -n regula-idv deploy/idv-backoffice -- \
  idv user create \
    --name regula-idv \
    --password '<your_password>' \
    --email '<your_email>' \
    --roles admin
```

Replace `<your_password>` and `<your_email>` with the credentials you want to use.

The command should confirm that the account was created:

```text
User: regula-idv
       User ID: <user_id>
       Email: <your_email>
       Roles: ['admin']
       Active: True
```

Keep the password in single quotation marks so that characters such as `@` are not interpreted by your shell.

## 6. Open the Portal

Forward the IDV Backoffice service to port `8080` on your local computer:

```bash
kubectl port-forward -n regula-idv svc/idv-backoffice 8080:80
```

Open <a href="http://127.0.0.1:8080" target="_blank" rel="noopener noreferrer">http://127.0.0.1:8080</a> and sign in with the administrator account you created.

## Setup Limitations

**Document and face verification.** IDV is running, but the services required to read documents and match faces are separate and are not installed by this setup. See [Production installation](./03-install-production.md) for deployment instructions.

**Phone scanning.** Phone scanning requires a public HTTPS address. This setup does not provide one, so you cannot use QR codes to open the scanning session on a phone. Browsers also require a secure context for camera access. For configuration details, see [Integrations](./04-integrations.md).

## Uninstall IDV

To remove IDV and its bundled dependencies, run:

```bash
helm uninstall idv -n regula-idv
kubectl delete namespace regula-idv
```

Deleting the namespace also removes the storage used by the bundled dependencies.
