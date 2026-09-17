# Troubleshooting

Find your symptom below. All examples assume the namespace `regula-idv` and release name `idv`.

## First commands to run

```bash
kubectl get pods -n regula-idv                          # what is running
kubectl describe pod -n regula-idv <pod>                # why it will not start
kubectl logs -n regula-idv <pod> --tail=200             # what it says
kubectl logs -n regula-idv <pod> --previous             # if it already restarted
```

## A pod never starts (`ContainerCreating`)

Usually a missing Secret.

```bash
kubectl describe pod -n regula-idv <pod> | tail -20
```

`secret "idv-license" not found` means either the Secret is not in this namespace, or its name does
not match `licenseSecretName`. Secrets do not cross namespaces — one created in `default` is
invisible here.

```bash
kubectl get secret -n regula-idv
```

Also check the name **inside** the Secret is exactly `regula.license`:

```bash
kubectl get secret idv-license -n regula-idv -o jsonpath='{.data}' | tr ',' '\n'
```

`--from-file=regula.license=./regula.license` gets this right. `--from-file=license=...` does not.

## Licence errors in the logs

Check the file arrived:

```bash
kubectl exec -n regula-idv deploy/idv-api -- ls -l /app/extBin/unix/regula.license
```

If it is there but rejected, it has expired, covers different features, or was corrupted — download
a fresh copy and recreate the Secret.

Licence checks may also need outbound access to `lic.regulaforensics.com`. If you use
`networkPolicy`, allow it; [`values.yaml`](../../charts/idv/values.yaml) has a commented example.

## Pods keep restarting (`CrashLoopBackOff`)

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

If the credentials look right but clearly are not being used, see
[subchart switches](05-configuration.md#careful-subchart-switches-overwrite-your-settings).

## The portal loads but I cannot sign in

**A new installation has no accounts.** Create one:

```bash
kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create --name admin --password '<password>' --email admin@example.com --roles admin
```

If it says the user already exists, the account is fine and the password is wrong.

If username and password are refused no matter what, check `config.basicAuth.enabled` is `true`:

```bash
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}' | grep -A1 basicAuth
```

See [Authentication and users](06-auth-and-users.md).

## QR codes or phone scanning do not work

Almost always `config.baseUrl`. It must be the address users actually visit:

```bash
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}' | grep baseUrl
kubectl get ingress -n regula-idv
```

The chart default, `http://idv.example.com`, points nowhere.

Two more causes:

- **No HTTPS.** Browsers block camera access on plain HTTP.
- **Using `port-forward`.** It only works on your own machine; a phone cannot reach `127.0.0.1`.
  Phone capture needs a real hostname, DNS, and a certificate.

## The address works but returns 404

The Ingress needs **both** `hosts` and `paths`. A host with no paths routes nothing:

```yaml
ingress:
  enabled: true
  hosts:
    - idv.example.com
  paths:
    - /          # required
```

```bash
kubectl get ingress -n regula-idv -o yaml | grep -A6 paths
```

## Search finds nothing / no Indexer running

The Indexer is deployed automatically when `config.faceSearch.enabled` or `config.textSearch.enabled`
is `true`. If neither is enabled, no Indexer pod exists, and search will not work.

```bash
kubectl get deploy -n regula-idv
```

If one of them is enabled and the Indexer still is not there, check the ConfigMap the chart rendered
to confirm the setting reached it — see [Configuration](05-configuration.md#how-it-works).

## My search settings are being ignored

`opensearch.enabled` is probably `true`. The bundled OpenSearch replaces every search connection
setting you supplied.

The same applies to `minio.enabled`, `mongodb.enabled`, and `rabbitmq.enabled`. See
[subchart switches](05-configuration.md#careful-subchart-switches-overwrite-your-settings).

## Nothing is being saved to storage

Check `config.storage.type` is `s3`, `az`, or `gcs`. Local filesystem storage (`fs`) is not available
for Kubernetes deployments and will not work if set.

## A setting from a Secret has no effect

You probably used `config.env` instead of the top-level `env`. Check whether the variable reached
the pod:

```bash
kubectl set env deploy/idv-api --list -n regula-idv | grep IDV_CONFIG
```

Nothing listed means it was never created. See
[Configuration](05-configuration.md#watch-out-env-and-configenv-are-different).

## Certificate errors on internal connections

Errors like `CERTIFICATE_VERIFY_FAILED` against your database, storage, search, or broker mean IDV
does not trust your certificate authority. Supply the CA certificate instead of rebuilding the
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

Expected. All services share one configuration, so a change restarts all of them. Run two or more
API and Workflow replicas with disruption budgets if you need no interruption — see
[Operations](07-operations.md#disruption-budgets).

## Information to send to support

```bash
kubectl get all -n regula-idv
kubectl describe pods -n regula-idv
kubectl logs -n regula-idv deploy/idv-api --tail=500
kubectl get configmap idv-config -n regula-idv -o jsonpath='{.data.idv-config}'
helm get values idv -n regula-idv
```

> **Remove sensitive data before sharing.** The last two commands can reveal connection strings,
> and — if they were not stored in Secrets — passwords and your encryption key.
