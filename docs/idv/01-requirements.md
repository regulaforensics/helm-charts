# Requirements

What to have ready before installing. IDV depends on services you provide — the chart does not set
up production-ready versions of them for you.

## Cluster

| | |
|---|---|
| Kubernetes | 1.23 or newer |
| Helm | 3.10 or newer |
| Ingress controller | Needed to reach IDV from outside the cluster |
| KEDA | Optional, only for queue-based autoscaling |
| Gateway API | Optional, only if you prefer it to Ingress |

## Services you provide

| What | Used for | Options | Required |
|---|---|---|---|
| **Database** | All records | MongoDB 8.0+, or MongoDB Atlas (recommended) | **Yes** |
| **Message queue** | Passing work between services | RabbitMQ, AmazonMQ 3.x+ | **Yes** |
| **File storage** | Images, documents, results | S3 or compatible (incl. MinIO), Azure Blob, Google Cloud Storage | **Yes** |
| **Search database** | Face and text search | OpenSearch 2.19.0+, or MongoDB Atlas | No |
| **Document Reader** | Reading identity documents | [`docreader`](../../charts/docreader/README.md) 8.1+ | No |
| **Face API** | Face matching and liveness | [`faceapi`](../../charts/faceapi/README.md) 7.1+ | No |
| **Metrics collector** | Monitoring | Prometheus with statsd_exporter | No |

Worth knowing:

- **Files are stored in object storage**, not on local disk. Use S3 or an S3-compatible service, or
  MinIO if you need something inside the cluster.
- **The message queue must speak AMQP**, such as RabbitMQ or AmazonMQ.
- **Search is needed for the Profile module**, as well as for face and text search.

## Resources

### Node capacity

Minimum hardware per service instance:

| Service | CPU | Memory |
|---|---|---|
| API | 2 vCPU | 2 GiB |
| Workflow | 2 vCPU | 2 GiB |
| Scheduler | 1 vCPU | 1 GiB |
| Audit | 1 vCPU | 1 GiB |

Use these figures to size the nodes that will host IDV. They describe the machine running a service,
not the pod's resource request — set requests from the values in the next section instead.

### Requests and limits

The chart ships without requests or limits, so nothing is reserved or capped until you set them.
Recommended values:

```yaml
api:
  resources:
    requests: { cpu: "650m", memory: "1200Mi" }
    limits:   { memory: "2Gi" }

workflow:
  replicas: 2
  resources:
    requests: { cpu: "200m", memory: "512Mi" }
    limits:   { memory: "768Mi" }

scheduler:
  resources:
    requests: { cpu: "300m", memory: "512Mi" }
    limits:   { memory: "3Gi" }

audit:
  resources:
    requests: { cpu: "150m", memory: "256Mi" }
    limits:   { memory: "2Gi" }

indexer:
  resources:
    requests: { cpu: "150m", memory: "256Mi" }
    limits:   { memory: "1536Mi" }
```

Three conventions to keep:

- **Memory limits on every component**, so a leak cannot take a node down.
- **No CPU limits**, so a busy service bursts instead of being throttled.
- **Limits above requests**, giving headroom for spikes without reserving it permanently.

Together these request roughly **1.5 CPU and 2.7 GiB** for one replica of each service, plus about
0.2 CPU and 0.5 GiB for the second Workflow replica. Your database, message queue, and storage need
capacity on top, wherever they run.

Handle higher load by scaling out rather than up — the API and Workflow both support autoscaling. See
[Operations](07-operations.md#scaling).

### Tune to your load

These values suit moderate verification volume. Requirements grow with the number of verifications,
the complexity of your workflows, and whether search is enabled. Check actual consumption and adjust:

```bash
kubectl top pods -n regula-idv
```

If memory use sits close to a limit, raise the limit before the pod starts being restarted.

### Face API and GPU

If you run Face API, use GPU nodes in production. GPU memory matters more than processing speed — a
16 GB card such as an NVIDIA Tesla T4 handles roughly four parallel workers. Configure this in the
[`faceapi` chart](../../charts/faceapi/README.md), not in IDV.

## Licence

IDV needs a `regula.license` file, available from the
[Client Portal](https://client.regulaforensics.com/). You load it into a Kubernetes Secret during
installation; it is never included in the chart.

## The bundled dependencies are for demos only

The chart can install MongoDB, RabbitMQ, MinIO, and OpenSearch for you. This makes a demo quick to
set up, but they are single-copy, use well-known passwords, and are not backed up.

**Do not use these four in production.** Run each dependency properly, with its own backups,
passwords, and monitoring.

The bundled StatsD exporter is the exception. It stores nothing and is fine to use in production if
you collect metrics — see [Integrations](04-integrations.md#metrics).

The [Quickstart](02-quickstart.md) uses them. The
[Production install](03-install-production.md) does not.

## Next

- Just want to see it working → [Quickstart](02-quickstart.md)
- Installing for real → [Production install](03-install-production.md)

---

Dependency versions, node capacity, and the GPU recommendation follow the
[Regula IDV deployment documentation](https://docs.regulaforensics.com/develop/idv/administration/deployment/).
