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

Rolling back:

```bash
helm history idv -n regula-idv
helm rollback idv <revision> -n regula-idv
```

Rollback restores settings only. It does **not** undo database changes, and it cannot recover data
if the encryption key changed.

## Scaling

Only **API** and **Workflow** can run multiple copies. Scheduler, Audit, and Indexer must stay at
one. Two schedulers would run every scheduled job twice.

Fixed number:

```yaml
api:
  replicas: 3
workflow:
  replicas: 4
```

### Automatic scaling on CPU and memory

```yaml
api:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

Requires metrics-server in the cluster. Once enabled, the autoscaler controls the replica count and
`replicas` is ignored.

### Automatic scaling on queue length (KEDA)

KEDA is recommended for Workflow when workload is driven by queue depth. Requires the KEDA
operator. Cannot be combined with the CPU autoscaler above.

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

Scale the API on request volume and Workflow on queue length. See
[Integrations](04-integrations.md#metrics).

## Disruption budgets

It's recommended to enable `podDisruptionBudget` for production environments. It will prevent Kubernetes from stopping all copies of a service at the same time during maintenance:

```yaml
api:
  podDisruptionBudget:
    enabled: true
    config:
      minAvailable: 1
```

Set `minAvailable` **or** `maxUnavailable`, never both. Only use these with two or more replicas. 
With a single replica, the budget blocks routine node maintenance entirely.

## Checking health

To check the status of the IDV services, run the commands as in the example:

```bash
kubectl get pods -n regula-idv
kubectl exec -n regula-idv deploy/idv-api -- curl -sf localhost:8000/api/health
kubectl logs -n regula-idv deploy/idv-workflow --tail=100 -f
```

The API provides a health endpoint. Port 8000 is fixed and must not be changed. 

For other components (`workflow`, `scheduler`, `audit`), check pod status and logs. For `workflow`, also check the queue length. The commands are the same as in the example above. In the example, `--tail=100` option will show the last 100 lines of the log for `workflow`. 

For more detailed logs, temporarily set the logging level to `DEBUG`:

```yaml
config:
  logging:
    level: DEBUG
```

Leave `console: true` and `file: false` so logs go to `kubectl logs` rather than inside the
container.

## Data retention

By default, session data is kept forever. If your organization has a data retention policy, configure the `cleanSessions` scheduled job to remove older session data. If you have a retention policy, see
[Configuration](05-configuration.md#scheduled-clean-up-jobs).

## Backups

IDV itself stores nothing. Back up what it depends on:

| What | Why |
|---|---|
| Database | Stores IDV records. Encrypt backups to protect the data |
| Object storage | Stores images, documents, and other persistent files |
| Encryption key | Required to decrypt data restored from a database backup |
| `values.yaml` | Contains the configuration needed to recreate the deployment |

Search indexes can be rebuilt, so backing them up is optional.

> A database backup and the encryption key are only useful together. Store both, and check you can
> actually restore them.

## Disaster recovery

IDV is deployed in your own infrastructure, so you are responsible for setting up disaster recovery. The appropriate approach depends on your recovery objectives and infrastructure. Options range from backup and restore to running IDV across two sites.

Beyond basic backups, the parts holding data need copying between sites: database replica sets,
storage replication, search replication, and broker clustering. The remaining services are
stateless and simply run in both places behind a load balancer.

The trade-offs between approaches are covered in the
[platform disaster recovery guide](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).

## Removing IDV

```bash
helm uninstall idv -n regula-idv
```
It removes the IDV application resources but does not delete your Secrets and data in object storage. Deleting the namespace removes them so
**make sure the encryption key is saved elsewhere first.**

---

Disaster recovery guidance summarised from the
[Regula IDV disaster recovery documentation](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).
