# Production install

The [Quickstart](02-quickstart.md) is an all-in-one installation that installs IDV together with bundled MongoDB, RabbitMQ, and MinIO services. It is designed for getting IDV up and running quickly.

The production installation integrates IDV into your existing infrastructure, connecting to MongoDB, a message broker, and object storage that you run yourself outside the IDV Helm deployment.

Before you start, make sure those three are reachable from the cluster and that you have
credentials for each. See [Requirements](01-requirements.md).

Main steps: 

- [Step 1. Create the namespace and license secret](#1-create-the-namespace-and-license)
- [Step 2. Generate the encryption key](#2-generate-the-encryption-key)
- [Step 3. Configure credentials](#3-configure-credentials)
- [Step 4. Configure the address and HTTPS](#4-configure-the-address-and-https)
- [Step 5. Configure `values.yaml`](#5-configure-valuesyaml)
- [Step 6. Install IDV](#6-install-idv)
- [Step 7. Create the first user](#7-create-the-first-user)
- [Check before going live](#check-before-going-live)
- [Next](#next)

## 1. Create the namespace and license

Create the namespace where IDV will be installed, then add the license. The key inside the Secret must be exactly `regula.license`.

```bash
kubectl create namespace regula-idv

kubectl create secret generic idv-license \
  --namespace regula-idv \
  --from-file=regula.license=./regula.license
```

## 2. Generate the encryption key

IDV encrypts sensitive database fields with a "Fernet key". Generate one:

```bash
pip install cryptography
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

> **Save this key in your password manager or secrets vault now.**
>
> - Without it, encrypted data cannot be recovered. There is no way to regenerate it.
> - Never keep the chart's default key. It is published publicly in this repository, so data
>   encrypted with it is not protected. Helm prints a warning after installing if you leave it in
>   place, or if no key is set at all.
> - Set it before storing real data. Changing it later makes existing encrypted data unreadable.

## 3. Configure credentials

Create the credentials Secret. Store passwords, connection strings, and other sensitive connection details in a Kubernetes Secret:

```bash
kubectl create secret generic idv-secrets \
  --namespace regula-idv \
  --from-literal=fernetKey='<your-generated-key>' \
  --from-literal=mongoUrl='mongodb://idv:PASSWORD@mongo.example.com:27017/idv?replicaSet=rs0&tls=true' \
  --from-literal=messageBrokerUrl='amqps://idv:PASSWORD@rabbitmq.example.com:5671/' \
  --from-literal=s3AccessKey='<access-key>' \
  --from-literal=s3AccessSecret='<access-secret>'
```

- `<your-generated-key>` → key from step 2
- `mongoUrl` → your MongoDB connection string
- `messageBrokerUrl` → your RabbitMQ connection string
- `<access-key>` / `<access-secret>` → your object-storage credentials

Step 5 below connects these values to IDV through the `env:` list. Do not put credentials directly under `config:`, where they would be stored as plain-text configuration values.

> Use the **top-level `env:`**, never `config.env:`. They are separate configuration options. See [Configuration](05-configuration.md#watch-out-env-and-configenv-are-different).

## 4. Configure the address and HTTPS

Two requirements that cause most first-install problems:

- **`config.baseUrl` must be the URL your users will enter in their browser to access your IDV instance.** Use your own domain, not `idv.example.com` from this example. The same domain must be configured in the Ingress `hosts` section below. IDV uses this address in QR codes, emails, and login redirects. If it is incorrect, the portal may still load, but phone-based and browser-based scanning can fail.

- **HTTPS is required** for document and face capture. Browsers block camera access over plain HTTP.
Terminate TLS at your Ingress or load balancer.

Your Ingress configuration needs **both** `hosts` and `paths`. A host without a path does not route traffic to IDV:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - idv.example.com
  paths:
    - /                    # required
  tls:
    - secretName: idv-tls
      hosts:
        - idv.example.com
```

This sends traffic to the API service. Expose only the API; the other services stay internal.

If you use Gateway API instead, configure `route.main` and keep `ingress.enabled: false`.

## 5. Configure `values.yaml`

A complete starting configuration. Adjust hostnames, buckets, and sizing.

```yaml
licenseSecretName: idv-license

image:
  # Always pin the version in production.
  tag: "3.9.1"
  pullPolicy: IfNotPresent

config:
  
  # The URL users will enter in their browser to access your IDV instance.
  # Replace `idv.example.com` with your own domain.
  # Must match the Ingress hostname below.
  baseUrl: "https://idv.example.com"

  # Left empty on purpose — the real values arrive from idv-secrets via `env` below.
  fernetKey: ""
  mongo:
    url: ""
  messageBroker:
    url: ""

  storage:
    type: s3
    s3:
      endpoint: "s3.eu-central-1.amazonaws.com"
      region: "eu-central-1"
      secure: true
    # Eight data types sharing one bucket (`idv-prod`), separated by prefix.
    # Replace `idv-prod` with the name of your bucket.
    # It's recommended to keep the prefixes unchanged.
    sessions:  { location: { bucket: "idv-prod", prefix: "sessions" } }
    persons:   { location: { bucket: "idv-prod", prefix: "persons" } }
    workflows: { location: { bucket: "idv-prod", prefix: "workflows" } }
    userFiles: { location: { bucket: "idv-prod", prefix: "files" } }
    locales:   { location: { bucket: "idv-prod", prefix: "localization" } }
    assets:    { location: { bucket: "idv-prod", prefix: "assets" } }
    tempFiles: { location: { bucket: "idv-prod", prefix: "tmp", folder: "files" } }
    banlists:  { location: { bucket: "idv-prod", prefix: "banlist" } }

  logging:
    level: INFO
    console: true
    file: false

# Sensitive credentials are loaded from the `idv-secrets` Secret.
# Do not put passwords, connection strings, or keys directly under `config:`.
env:
  - name: IDV_CONFIG__FERNETKEY
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: fernetKey }
  - name: IDV_CONFIG__MONGO__URL
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: mongoUrl }
  - name: IDV_CONFIG__MESSAGEBROKER__URL
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: messageBrokerUrl }
  - name: IDV_CONFIG__STORAGE__S3__ACCESSKEY
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: s3AccessKey }
  - name: IDV_CONFIG__STORAGE__S3__ACCESSSECRET
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: s3AccessSecret }

# Recommended values. Tune to your load — see 01-requirements.md.
api:
  replicas: 2
  resources:
    requests: { cpu: "650m", memory: "1200Mi" }
    limits:   { memory: "2Gi" }
  podDisruptionBudget:
    enabled: true
    config:
      minAvailable: 1

workflow:
  replicas: 2
  resources:
    requests: { cpu: "200m", memory: "512Mi" }
    limits:   { memory: "768Mi" }
  podDisruptionBudget:
    enabled: true
    config:
      minAvailable: 1

scheduler:
  resources:
    requests: { cpu: "300m", memory: "512Mi" }
    limits:   { memory: "3Gi" }

audit:
  resources:
    requests: { cpu: "150m", memory: "256Mi" }
    limits:   { memory: "2Gi" }

ingress:
  enabled: true
  className: nginx
 # Must match config.baseUrl above.
  hosts:
    - idv.example.com
  paths:
    - /
  tls:
    - secretName: idv-tls
      hosts:
        - idv.example.com

# Bundled data stores stay off — you manage your own.
mongodb:
  enabled: false
rabbitmq:
  enabled: false
minio:
  enabled: false
opensearch:
  enabled: false

# The statsd exporter is stateless and safe to enable if you collect metrics.
statsd:
  enabled: false
```

Create the bucket before installing IDV. The chart does not create it for you. Follow the instructions for your cloud provider:
- <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html" target="_blank" rel="noopener noreferrer">AWS</a>
- <a href="https://docs.cloud.google.com/storage/docs/creating-buckets" target="_blank" rel="noopener noreferrer">GCP</a>
- <a href="https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal" target="_blank" rel="noopener noreferrer">Azure</a>

## 6. Install IDV

Preview first. This helps catch configuration mistakes before they are applied to the cluster:

```bash
helm template idv regulaforensics/idv \
  --namespace regula-idv \
  -f values.yaml > preview.yaml
```

In `preview.yaml`, verify that:

* `baseUrl` is set to the address users will access
* Ingress has both a host and a path
* The default Fernet key is not present

If everything looks correct, install IDV:

```bash
helm install idv regulaforensics/idv \
  --namespace regula-idv \
  -f values.yaml \
  --wait --timeout 10m
```

Check that the pods have started:

```bash
kubectl get pods -n regula-idv
kubectl exec -n regula-idv deploy/idv-api -- curl -sf localhost:8000/api/health
```

A healthy installation should have these four IDV components running:

* `api`
* `workflow`
* `scheduler`
* `audit`

A successful request returns 200. 

There is no `indexer` component unless you enable search.

If something went wrong, see [Troubleshooting](08-troubleshooting.md)

## 7. Create the first user

**A new installation has no accounts and no default password.** Nobody can log in until you create
the first account:

```bash
printf 'New admin password: '; read -rs IDV_ADMIN_PW; echo

kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create \
    --name admin \
    --password "$IDV_ADMIN_PW" \
    --email admin@example.com \
    --roles admin

unset IDV_ADMIN_PW
```

The password is read without displaying it on screen and is stored temporarily in the `IDV_ADMIN_PW` shell variable instead of being written directly in the command. Run `unset IDV_ADMIN_PW` after the account is created to remove the variable.
See [Authentication and users](06-auth-and-users.md) for SSO and roles.

You can now open `https://idv.example.com` and sign in.

## Check before going live

- [ ] Fernet key generated, passed via Secret, and backed up somewhere safe
- [ ] HTTPS everywhere, using TLS 1.2 or newer
- [ ] Encryption at rest enabled on the database, storage, search, and broker
- [ ] Broker uses `amqps://`, MongoDB uses `tls=true`
- [ ] All credentials in Secrets, none under `config:`
- [ ] Image version pinned
- [ ] Resource requests set on every service
- [ ] Disruption budgets on API and Workflow
- [ ] Only the API reachable from outside
- [ ] `networkPolicy.enabled` is disabled by default. Enable it with caution. It is intended for advanced users who understand Kubernetes network policies and can configure them appropriately for their environment. 
- [ ] Backups running for the database and storage

Using your own certificate authority for internal connections? See
[Troubleshooting](08-troubleshooting.md#certificate-errors-on-internal-connections).

## Next

- Add document and face verification → [Integrations](04-integrations.md)
- Day-to-day running → [Operations](07-operations.md)

---

Security recommendations follow the
[Regula IDV security documentation](https://docs.regulaforensics.com/develop/idv/administration/security/).
