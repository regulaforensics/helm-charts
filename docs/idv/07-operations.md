# Operations

Running IDV day to day.

## Upgrades

Keep `values.yaml` in version control and always pass the same file:

```bash
helm repo update
helm upgrade idv regulaforensics/idv \
  --namespace regula-idv \
  -f values.yaml \
  --wait --timeout 10m
```

Three things to know:

- **Pin `image.tag`.** Otherwise the application version changes whenever you update the chart
  repository.
- **`--version` controls the chart version.** An upgrade can change the chart as well as the app.
- **Any config change restarts all services**, because they share one configuration.

Going back:

```bash
helm history idv -n regula-idv
helm rollback idv <revision> -n regula-idv
```

Rollback restores settings only. It does **not** undo database changes, and it cannot recover data
if the encryption key changed.

## Scaling

Only **API** and **Workflow** can run multiple copies. Scheduler, Audit, and Indexer must stay at
one — two schedulers would run every scheduled job twice.

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

Better suited to Workflow, whose load shows up as a queue rather than as CPU. Requires the KEDA
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

These stop Kubernetes taking all copies of a service down at once during maintenance:

```yaml
api:
  podDisruptionBudget:
    enabled: true
    config:
      minAvailable: 1
```

Set `minAvailable` **or** `maxUnavailable`, never both. Only use these with two or more replicas —
on a single copy, the budget blocks routine node maintenance entirely.

## Checking health

```bash
kubectl get pods -n regula-idv
kubectl exec -n regula-idv deploy/idv-api -- curl -sf localhost:8000/api/health
kubectl logs -n regula-idv deploy/idv-workflow --tail=100 -f
```

Only the API has a health address. Judge the others by pod status, logs, and queue length.

For more detail temporarily:

```yaml
config:
  logging:
    level: DEBUG
```

Leave `console: true` and `file: false` so logs go to `kubectl logs` rather than inside the
container.

## Data retention

**Session data is kept forever unless you say otherwise.** If you have a retention policy, see
[Configuration](05-configuration.md#scheduled-clean-up-jobs).

## Backups

IDV itself stores nothing. Back up what it depends on:

| What | Why |
|---|---|
| Database | All records live here. Encrypt the backups |
| Object storage | Images and documents |
| Encryption key | Without it, a database backup is unreadable |
| `values.yaml` | So the installation can be rebuilt |

Search indexes can be rebuilt, so backing them up is optional.

> A database backup and the encryption key are only useful together. Store both, and check you can
> actually restore them.

## Disaster recovery

Every IDV service can run in more than one place, so any standard approach works — from simple
backup and restore through to two live sites. IDV is not a cloud service, so this is set up in your
own infrastructure.

Beyond basic backups, the parts holding data need copying between sites: database replica sets,
storage replication, search replication, and broker clustering. The remaining services are
stateless and simply run in both places behind a load balancer.

The trade-offs between approaches are covered in the
[platform disaster recovery guide](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).

## Removing IDV

```bash
helm uninstall idv -n regula-idv
```

This leaves your Secrets and any storage claims behind. Deleting the namespace removes them —
**make sure the encryption key is saved elsewhere first.**

---

Disaster recovery guidance summarised from the
[Regula IDV disaster recovery documentation](https://docs.regulaforensics.com/develop/idv/administration/disaster-recovery/).
