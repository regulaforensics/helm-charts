# Production install

Installs IDV against MongoDB, a message broker, and object storage that you run yourself.

Before you start, make sure those three are reachable from the cluster and that you have
credentials for each. See [Requirements](01-requirements.md).

Seven steps:

1. Namespace and license
2. Encryption key
3. Credentials
4. Address and HTTPS
5. `values.yaml`
6. Install
7. First user

## 1. Namespace and license

```bash
kubectl create namespace regula-idv

kubectl create secret generic idv-license \
  --namespace regula-idv \
  --from-file=regula.license=./regula.license
```

The key inside the Secret must be exactly `regula.license`.

## 2. Encryption key

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

## 3. Credentials

Put every password and connection string into a Secret:

```bash
kubectl create secret generic idv-secrets \
  --namespace regula-idv \
  --from-literal=fernetKey='<your-generated-key>' \
  --from-literal=mongoUrl='mongodb://idv:PASSWORD@mongo.example.com:27017/idv?replicaSet=rs0&tls=true' \
  --from-literal=messageBrokerUrl='amqps://idv:PASSWORD@rabbitmq.example.com:5671/' \
  --from-literal=s3AccessKey='<access-key>' \
  --from-literal=s3AccessSecret='<access-secret>'
```

Step 5 connects these to IDV through the `env:` list. Anything you put under `config:` instead is
stored in plain text, so credentials always go here.

> Use the **top-level `env:`**, never `config.env:` — they are unrelated, and the second one fails
> silently. See [Configuration](05-configuration.md#watch-out-env-and-configenv-are-different).

## 4. Address and HTTPS

Two requirements that cause most first-install problems:

**`config.baseUrl` must be the address your users actually visit**, matching the hostname on your
Ingress. IDV puts this address into QR codes, emails, and login redirects. Get it wrong and the
portal still loads, but phone and browser scanning silently fail.

**HTTPS is required** for document and face capture. Browsers block camera access over plain HTTP.
Terminate TLS at your Ingress or load balancer.

Also note the Ingress needs **both** `hosts` and `paths`. A host with no paths routes nothing:

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

This sends traffic to the API service. Expose only the API; the other four services stay internal.

Using Gateway API instead? Configure `route.main` and leave `ingress.enabled: false`.

## 5. values.yaml

A complete starting file. Adjust hostnames, buckets, and sizing.

```yaml
licenseSecretName: idv-license

image:
  # Always pin the version in production.
  tag: "3.9.1"
  pullPolicy: IfNotPresent

config:
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
    # Eight data types sharing one bucket, separated by prefix.
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

# Credentials from the Secret created in step 3.
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

Create the bucket before installing. The chart does not create it for you.

## 6. Install

Preview first — this catches most mistakes before they reach the cluster:

```bash
helm template idv regulaforensics/idv \
  --namespace regula-idv -f values.yaml > preview.yaml
```

In `preview.yaml`, check that `baseUrl` is right, the Ingress has a path, and the default Fernet
key is gone.

Then install:

```bash
helm install idv regulaforensics/idv \
  --namespace regula-idv \
  -f values.yaml \
  --wait --timeout 10m
```

Check it started:

```bash
kubectl get pods -n regula-idv
kubectl exec -n regula-idv deploy/idv-api -- curl -sf localhost:8000/api/health
```

You should see four services running: `api`, `workflow`, `scheduler`, and `audit`. There is no
`indexer` unless you enable search.

Something wrong? → [Troubleshooting](08-troubleshooting.md)

## 7. First user

**A new installation has no accounts and no default password.** Nobody can log in until you create
the first one:

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

Reading the password into a variable keeps it out of your shell history. See
[Authentication and users](06-auth-and-users.md) for SSO and roles.

You can now open `https://idv.example.com` and sign in.

## Before going live

- [ ] Fernet key generated, passed via Secret, and backed up somewhere safe
- [ ] HTTPS everywhere, using TLS 1.2 or newer
- [ ] Encryption at rest enabled on the database, storage, search, and broker
- [ ] Broker uses `amqps://`, MongoDB uses `tls=true`
- [ ] All credentials in Secrets, none under `config:`
- [ ] Image version pinned
- [ ] Resource requests set on every service
- [ ] Disruption budgets on API and Workflow
- [ ] Only the API reachable from outside
- [ ] `networkPolicy.enabled: true`
- [ ] Backups running for the database and storage

Using your own certificate authority for internal connections? See
[Troubleshooting](08-troubleshooting.md#certificate-errors-on-internal-connections).

## Next

- Add document and face verification → [Integrations](04-integrations.md)
- Day-to-day running → [Operations](07-operations.md)

---

Security recommendations follow the
[Regula IDV security documentation](https://docs.regulaforensics.com/develop/idv/administration/security/).
