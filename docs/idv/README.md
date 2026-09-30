# Regula IDV Platform on Kubernetes

How to install and configure Regula Identity Verification (IDV) Platform.

Kubernetes is the supported way to run IDV. These pages cover it from a quick demo through to a
production installation.

| | |
|---|---|
| Chart version | `1.16.0` |
| Application version | `3.9.1` |
| Kubernetes | 1.23 or newer |
| Helm | 3.10 or newer |

## Where to Start

| | |
|---|---|
| **[1. Requirements](01-requirements.md)** | What you need before installing |
| **[2. Quickstart](02-quickstart.md)** | A working demo in about 10 minutes |
| **[3. Production installation](03-install-production.md)** | 	Production installation, step by step |
| **[4. Integrations](04-integrations.md)** | Document scanning, face matching, search, email |
| **[5. Configuration](05-configuration.md)** | Where settings live and how to change them |
| **[6. Users and sign-in](06-auth-and-users.md)** | First account, SSO, roles |
| **[7. Operations](07-operations.md)** | Upgrades, scaling, backups |
| **[8. Troubleshooting](08-troubleshooting.md)** | When something does not work |

New to this? Read [Requirements](01-requirements.md), then follow the
[Quickstart](02-quickstart.md) to see IDV working before planning a real installation.

## What IDV Is

IDV checks that people are who they claim to be, combining document verification, face verification,
and data checks into one process you can configure.

It is not a single application. It is five services that work together, plus a database, a message
queue, and file storage that you provide.

## The Five Services

> **Note:** In version 3.10, the `api` component was renamed to `backoffice`. The `api` component name remains supported for backward compatibility (for v.3.10), but we recommend updating your configuration to use `backoffice`.

| Service | What it does | Can run multiple copies |
|---|---|---|
| **Backoffice** | Handles all incoming requests and serves the web portal | Yes |
| **Workflow** | Runs the verification steps | Yes |
| **Scheduler** | Runs scheduled clean-up tasks | No |
| **Audit** | Records what happened, for compliance | No |
| **Indexer** | Builds search indexes | No |

Only the Backoffice is reachable from outside. The others talk to each other internally.

The Indexer is only installed when search is switched on — see
[Integrations](04-integrations.md#the-indexer).

## Before You Begin

**There is no default password.** A new installation has no accounts at all. You create the first
one with a single command after installing. See [Users and sign-in](06-auth-and-users.md).

**Change the encryption key.** The chart includes a working default key that is published publicly,
so anyone who leaves it in place ends up with data protected by a key everybody can read. Helm warns
you after installing if you do. See [Production installation](03-install-production.md#2-encryption-key).

**The address in `config.baseUrl` must be the one users actually visit.** It goes into QR codes,
emails, and sign-in redirects. If it is wrong, the portal still loads but phone scanning quietly
fails. See [Production installation](03-install-production.md#4-address-and-https).

## Key Terms

| Term | Meaning |
|---|---|
| Chart | The installable package for Kubernetes, installed with Helm |
| `values.yaml` | Your settings file, controlling how IDV is installed |
| Namespace | A named area of the cluster. These guides use `regula-idv` |
| Secret | Where Kubernetes stores passwords and keys |
| Ingress | The rule that lets traffic from outside reach IDV |
| Subchart | An optional bundled dependency, for demos only |

## Configuration Reference

The [chart README](../../charts/idv/README.md) lists every parameter. These pages explain the ones
that matter and the order to set them in, rather than repeating the full table.

## Related Services

Document and face verification come from two separate Regula services, both published from this
repository:

- [`docreader`](../../charts/docreader/README.md) — reads identity documents
- [`faceapi`](../../charts/faceapi/README.md) — detects and matches faces

IDV starts without them, but verification needs at least one. See
[Integrations](04-integrations.md).
