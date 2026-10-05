# Operations

This section covers day-to-day operations of a production IDV deployment, including upgrades, scaling, health checks, backups, disaster recovery, and removal.

## Upgrades

Keep `values.yaml` in version control and always pass the same file:

```bash
helm repo update
helm upgrade idv regulaforensics/idv \
  --namespace regula-idv \
  -f values.yaml \
  --wait --timeout 10m
```

Before upgrading:

- **Set `image.tag` to a specific application version**. This prevents the application version from changing unexpectedly when you update the Helm chart.
- **`--version` controls the chart version.** An upgrade can change the chart as well as the app.
- **Any config change restarts all services**, because they share one configuration.

To roll back an upgrade, run:

```bash
helm history idv -n regula-idv
helm rollback idv <revision> -n regula-idv
```

Rollback restores settings only. It does **not** undo database changes, and it cannot recover data
if the encryption key changed.

## Scaling

Only `backoffice` and `workflow` can run multiple copies. `scheduler`, `audit`, and `indexer` must stay at
one. Running multiple `scheduler` replicas causes each scheduled job to run multiple times.

To configure a fixed number of replicas:

```yaml
backoffice:
  replicas: 3
workflow:
  replicas: 4
```

### Automatic scaling on CPU and memory

```yaml
backoffice:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

Requires `metrics-server` in the cluster. Once enabled, the autoscaler controls the replica count and
`replicas` is ignored.

### Automatic scaling on queue length (KEDA)

KEDA is recommended for `workflow` when workload is driven by queue depth. Queue-based automatic scaling requires the KEDA operator and cannot be combined with the CPU and memory autoscaler described above. 

```yaml
workflow:
  autoscaling:
    enabled: true
    keda:
      enabled: true
      minReplicaCount: 2
      maxReplicaCount: 20
      triggers:
        - type: rabbitmq
          metadata:
            protocol: amqp
            queueName: workflow
            mode: QueueLength
            value: "50"
          authenticationRef:
            name: idv-workflow-keda-auth
      # Hold steady if the queue cannot be read, instead of scaling to nothing.
      fallback:
        failureThreshold: 3
        replicas: 2
```

Scale the `backoffice` on request volume and `workflow` on queue length. See
[Integrations](04-integrations.md#metrics).

## Disruption Budgets

It's recommended to enable `podDisruptionBudget` in production environments to prevent Kubernetes from stopping all replicas of a service during maintenance:

```yaml
backoffice:
  podDisruptionBudget:
    enabled: true
    config:
      minAvailable: 1
```

Set `minAvailable` or `maxUnavailable`, never both. Only use these with two or more replicas. 
With a single replica, the budget blocks routine node maintenance entirely.

## Check Health

To check the status of the IDV services, run the commands as in the example:

```bash
kubectl get pods -n regula-idv
kubectl exec -n regula-idv deploy/idv-backoffice -- curl -sf localhost:8000/api/health
kubectl logs -n regula-idv deploy/idv-workflow --tail=100 -f
```

The `backoffice` provides a health endpoint. Port 8000 is fixed and must not be changed.

For `workflow`, `scheduler`, and `audit`, check the pod status and logs. For `workflow`, also check the queue length. The `--tail=100` option displays the last 100 log lines.

For more detailed logs, temporarily set the logging level to `DEBUG`:

```yaml
config:
  logging:
    level: DEBUG
```

Leave `console: true` and `file: false` so logs go to `kubectl logs` rather than inside the
container.

## Data Retention

By default, session data is kept indefinitely. If your organization has a data retention policy, configure the `cleanSessions` scheduled job to remove older session data. Also see
[Configuration](05-configuration.md#scheduled-clean-up-jobs).

## Backups

IDV itself stores nothing. Back up what it depends on:

| What | Why |
|---|---|
| Database | Stores IDV records. Encrypt backups to protect data |
| Object storage | Stores images, documents, and other persistent files |
| Encryption key | Required to decrypt data restored from a database backup |
| `values.yaml` | Contains the configuration needed to recreate the deployment |

Search indexes can be rebuilt, so backing them up is optional.

> **Important**
>
> A database backup and its encryption key are required together for recovery. Store both securely and regularly verify that you can restore them.

## Disaster Recovery

IDV is deployed in your own infrastructure, so you are responsible for setting up disaster recovery. The appropriate approach depends on your recovery objectives and infrastructure. Options range from backup and restore to running IDV across two sites.

For multi-site deployments, replicate stateful components between sites, including database replica sets, object storage, search indexes, and the message broker. The remaining IDV services are stateless and can run at both sites behind a load balancer.

The trade-offs between approaches are covered in the
[platform disaster recovery guide](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).

## Removing IDV

```bash
helm uninstall idv -n regula-idv
```
The command removes the IDV application resources but does not delete your Secrets and the volumes (PersistentVolumeClaims) of the bundled dependencies. Deleting the namespace removes them so
**make sure the encryption key is saved elsewhere first.**

The command removes the IDV application resources but does not delete data stored in external object storage.

---

Disaster recovery guidance summarised from the
[Regula IDV disaster recovery documentation](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).
