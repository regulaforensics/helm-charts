# Troubleshooting

Find your symptom below. All examples assume the namespace `regula-idv` and release name `idv`.

## Start here

Run these commands first:

```bash
kubectl get pods -n regula-idv                          
kubectl describe pod -n regula-idv <pod>               
kubectl logs -n regula-idv <pod> --tail=200             
kubectl logs -n regula-idv <pod> --previous             
```

| Command                                       | What it tells you                                                               |
| --------------------------------------------- | ------------------------------------------------------------------------------- |
| `kubectl get pods -n regula-idv`              | Shows which components are running, pending, or failing.                        |
| `kubectl describe pod -n regula-idv <pod>`    | Shows why a Pod is not starting, including events and configuration errors.     |
| `kubectl logs -n regula-idv <pod> --tail=200` | Shows recent application errors from the container.                             |
| `kubectl logs -n regula-idv <pod> --previous` | Shows logs from the previous container instance if the container has restarted. |

Common issues:

- [A Pod never starts (`ContainerCreating`)](#a-pod-never-starts-containercreating)
- [Licence errors in the logs](#licence-errors-in-the-logs)
- [Pods keep restarting (`CrashLoopBackOff`)](#pods-keep-restarting-crashloopbackoff)
- [The portal loads but I cannot sign in](#the-portal-loads-but-i-cannot-sign-in)
- [QR codes or phone scanning do not work](#qr-codes-or-phone-scanning-do-not-work)
- [The address works but returns 404](#the-address-works-but-returns-404)
- [Search finds nothing / no Indexer running](#search-finds-nothing--no-indexer-running)
- [My search settings are being ignored](#my-search-settings-are-being-ignored)
- [Nothing is being saved to storage](#nothing-is-being-saved-to-storage)
- [A setting from a Secret has no effect](#a-setting-from-a-secret-has-no-effect)
- [Certificate errors on internal connections](#certificate-errors-on-internal-connections)
- [Everything restarted after I changed a setting](#everything-restarted-after-i-changed-a-setting)


## A pod never starts (`ContainerCreating`)

### Likely cause

Usually a missing Secret.

### Check

```bash
kubectl describe pod -n regula-idv <pod> | tail -20
```

If you see `secret "idv-license" not found`, either the Secret is not in this namespace, or its name does not match `licenseSecretName`. Secrets do not cross namespaces, the one created in default is invisible here.

```bash
kubectl get secret -n regula-idv
```

Also check the name **inside** the Secret is exactly `regula.license`:

```bash
kubectl get secret idv-license -n regula-idv -o jsonpath='{.data}' | tr ',' '\n'
```

### Fix

`--from-file=regula.license=./regula.license` gets this right. `--from-file=license=...` does not.

## Licence errors in the logs

### Likely cause

The license file may be missing, expired, cover different features, or be corrupted. License checks may also need outbound access to `lic.regulaforensics.com`.

### Check

Check that the file arrived:

```bash
kubectl exec -n regula-idv deploy/idv-api -- ls -l /app/extBin/unix/regula.license
```

### Fix

If it is there but rejected, download
a fresh copy and recreate the Secret.

If you use
`networkPolicy`, allow outbound access to `lic.regulaforensics.com`; [`values.yaml`](../../charts/idv/values.yaml) has a commented example.

## Pods keep restarting (`CrashLoopBackOff`)

### Likely cause

An application error or a problem with one of the dependencies.

### Check

Read the logs, then check each dependency.

**Database.** Test the connection from inside the cluster:

```bash
kubectl run -it --rm mongosh-test --image=mongo:8 -n regula-idv --restart=Never -- \
  mongosh "<your-connection-string>" --eval 'db.runCommand({ping:1})'
```

**Message broker.** The address must match the port: `amqp://` for 5672, `amqps://` for 5671. A
secure broker addressed as `amqp://` hangs instead of failing clearly.

**Storage.** The bucket must already exist. Missing buckets usually appear as errors on the first
verification rather than at startup.

### Fix

If the credentials look right but clearly are not being used, see
[subchart switches](05-configuration.md#careful-subchart-switches-overwrite-your-settings).

## The portal loads but I cannot sign in

### Likely cause

**A new installation has no accounts.** 

### Check

Create one:

```bash
kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create --name admin --password '<password>' --email admin@example.com --roles admin
```

If it says the user already exists, the account is fine and the password is wrong.

If username and password are refused no matter what, check `config.basicAuth.enabled` is `true`:

```bash
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}' | grep -A1 basicAuth
```

### Fix

See [Authentication and users](06-auth-and-users.md).

## QR codes or phone scanning do not work

### Likely cause

Almost always `config.baseUrl`. It must be the address users actually visit. 

Two more causes are no HTTPS and using port-forward.

### Check

```bash
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}' | grep baseUrl
kubectl get ingress -n regula-idv
```

### Fix

The chart default, `http://idv.example.com`, points nowhere.

**No HTTPS.** Browsers block camera access on plain HTTP.
**Using `port-forward`.** It only works on your own machine; a phone cannot reach `127.0.0.1`.
  Phone capture needs a real hostname, DNS, and a certificate.

## The address works but returns 404

### Likely cause

The Ingress needs **both** `hosts` and `paths`. A host with no paths routes nothing.

```yaml
ingress:
  enabled: true
  hosts:
    - idv.example.com
  paths:
    - /          # required
```

### Check

```bash
kubectl get ingress -n regula-idv -o yaml | grep -A6 paths
```

### Fix

Add the `/` path if it is missing.

## Search finds nothing / no Indexer running

### Likely cause

The Indexer is deployed automatically when `config.faceSearch.enabled` or `config.textSearch.enabled`
is `true`. If neither is enabled, no Indexer pod exists, and search will not work.

### Check

```bash
kubectl get deploy -n regula-idv
```
If `faceSearch` or `textSearch` is enabled but the Indexer is still not running, check the ConfigMap to confirm that the setting was applied correctly. See [Configuration](05-configuration.md#how-it-works).

### Fix

Enable `config.faceSearch` or `config.textSearch` if search is required. And see about the Indexer in [Integrations](05-integrations.md#the-indexer).

## My search settings are being ignored

### Likely cause

`opensearch.enabled` is probably `true`. The bundled OpenSearch replaces every search connection
setting you supplied.

The same applies to `minio.enabled`, `mongodb.enabled`, and `rabbitmq.enabled`. 

### Check

Check whether the bundled [subchart](05-configuration.md#careful-subchart-switches-overwrite-your-settings). is enabled.

### Fix

See
[subchart switches](05-configuration.md#careful-subchart-switches-overwrite-your-settings).

## Nothing is being saved to storage

### Likely cause

`config.storage.type` is set to an unsupported value for Kubernetes deployments.

### Check

Check that `config.storage.type` is `s3`, `az`, or `gcs`. 

### Fix

Local filesystem storage (`fs`) is not available
for Kubernetes deployments and will not work if set.

## A setting from a Secret has no effect

### Likely cause

You probably used `config.env` instead of the top-level `env`. 

### Check

Check whether the variable reached
the pod:

```bash
kubectl set env deploy/idv-api --list -n regula-idv | grep IDV_CONFIG
```

Nothing listed means it was never created. 

### Fix

Use the top-level `env` setting. See
[Configuration](05-configuration.md#watch-out-env-and-configenv-are-different).

## Certificate errors on internal connections

### Likely cause

Errors like `CERTIFICATE_VERIFY_FAILED` against your database, storage, search, or broker mean IDV
does not trust your certificate authority. 

### Check

Check the affected connection for certificate verification errors in the logs.

### Fix

Supply the CA certificate instead of rebuilding the
image:

```yaml
tls:
  trustedCABundle:
    configMapName: my-ca-bundle    # ConfigMap containing ca-bundle.pem
```

The chart makes it available to all services automatically. Some connections also need the path
spelled out:

```
mongodb://…?tls=true&tlsCAFile=/etc/regula/tls/ca-bundle.pem
```

For OpenSearch set `verifyCerts: true`; for the broker use `amqps://`.

## Everything restarted after I changed a setting

### Likely cause

This is expected. All services share one configuration, so a change restarts all of them. 

### Check

This is expected behavior not a problem to diagnose.

### Fix

Run two or more
API and Workflow replicas with disruption budgets if you need no interruption. See
[Operations](07-operations.md#disruption-budgets).

## Information to send to support

If the issue persists, collect the following information:

```bash
kubectl get all -n regula-idv
kubectl describe pods -n regula-idv
kubectl logs -n regula-idv deploy/idv-api --tail=500
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}'
helm get values idv -n regula-idv
```

> **Remove sensitive data before sharing.** The last two commands can reveal connection strings. If passwords or your encryption key were not stored in Secrets, they may also be exposed.
