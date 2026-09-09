# Quickstart

A working IDV Platform in about ten minutes, using a bundled database, message queue, and file
storage.

> **For demos only.** The bundled dependencies use well-known passwords, store nothing safely, and
> the encryption key is the public default. Do not put real data in it. For anything real, use the
> [Production install](03-install-production.md).

## You need

- A Kubernetes cluster (1.23 or newer) and `kubectl` connected to it
- Helm 3.10 or newer
- A `regula.license` file from the [Client Portal](https://client.regulaforensics.com/)
- About 4 CPU cores and 8 GB free in the cluster

## 1. Add the chart repository

```bash
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

## 2. Create a namespace and add the licence

```bash
kubectl create namespace regula-idv

kubectl create secret generic idv-license \
  --namespace regula-idv \
  --from-file=regula.license=./regula.license
```

The name inside the Secret must be exactly `regula.license`.

## 3. Install

```bash
helm install idv regulaforensics/idv \
  --namespace regula-idv \
  --set licenseSecretName=idv-license \
  --set mongodb.enabled=true \
  --set rabbitmq.enabled=true \
  --set minio.enabled=true \
  --wait --timeout 10m
```

Those three switches install the bundled database, message queue, and file storage, and connect IDV
to them automatically. You do not need to configure any addresses or passwords.

Using `idv` as the release name keeps the service names short, like `idv-api`.

## 4. Check it started

```bash
kubectl get pods -n regula-idv
```

You should see:

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

`idv-minio-post-job` should show `Completed` — it runs once to prepare storage. There is no
`idv-indexer`, which is normal until search is enabled.

Something not running? → [Troubleshooting](08-troubleshooting.md)

## 5. Create your login

**A new installation has no accounts.** Create the first one:

```bash
kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create \
    --name regula-idv \
    --password 't3stP@ss' \
    --email regula@example.com \
    --roles admin
```

It confirms the account:

```
User: regula-idv
        User ID: 6a8d73f54e4d7a8bc485207f
        Email: regula@example.com
        Roles: ['admin']
        Active: True
```

Keep the password in quotes so characters like `@` are not misread by your shell.

## 6. Open the portal

```bash
kubectl port-forward -n regula-idv svc/idv-api 8080:80
```

Go to <http://127.0.0.1:8080> and sign in with the account above.

## What will not work yet

**Verifying documents or faces.** IDV is running, but the services that read documents and match
faces are separate and not installed. See [Integrations](04-integrations.md).

**Scanning with a phone.** This needs a real web address with HTTPS. The demo has neither, so QR
codes point nowhere and browsers block camera access. That is the
[Production install](03-install-production.md).

## Remove it

```bash
helm uninstall idv -n regula-idv
kubectl delete namespace regula-idv
```

Deleting the namespace also clears the storage the bundled dependencies left behind.

## Next

- Install it properly → [Production install](03-install-production.md)
- Add document and face verification → [Integrations](04-integrations.md)
