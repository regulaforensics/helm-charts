# Public docs sync — action list

For whoever edits docs.regulaforensics.com. Kubernetes/Helm is now the documented install method
in [`docs/idv/`](README.md) in this repo — use it as the source when updating the pages below.

---

## Page: `/develop/idv/overview/installation-example/`

In progress

- Replace the Docker Compose walkthrough with the Kubernetes quickstart. Use
  [`02-quickstart.md`](02-quickstart.md) as the source. Keep the same URL (it's linked/indexed).

## Page: `/develop/idv/administration/deployment/`

`DONE`

- Add a Kubernetes/Helm install procedure. Use [`03-install-production.md`](03-install-production.md)
  and link the chart repo: `https://github.com/regulaforensics/helm-charts`.
- **Services table:** add **Indexer** as a 5th service (also missing from the sizing table).
- **Sizing table:** label it as *node/machine* sizing. It is not the same as a Kubernetes
  `resources.requests` value — say so explicitly, or readers will over-provision pods 3–4×.
- **Message broker row:** Kafka is not an alternative to RabbitMQ/AmazonMQ for the main broker — it's
  used separately for the multi-site `replicationBus` feature. Split these into two rows.

## Page: `/develop/idv/administration/configuration/`

`DONE`

| Field | Change |
|---|---|
| `faceSearch.database.opensearch.indexName` | Rename to `method` |
| `oauth2.accessTokenTtl` default | `3600` → `600` |
| `logging.maxFileSize` default | Confirm before changing — three different values seen: docs `1048576`, chart `10485760`, app example `10048576` |
| `webApp.enabled` | Remove — not in the released application |
| `services.analytics` | Remove — not in the released application |

**Do not remove**, even though a Helm chart can't set them yet: `mode: standalone`,
`storage.type: fs`, `metrics.alerts`. All three are real, confirmed application features.

## Missing from the docs entirely

`Done`

Add these somewhere in the Kubernetes install/config pages — each is a real support-ticket source:

- No default login. First admin account must be created via `idv user create` after install. [Production install](03-install-production.md) ->  step 7. create the first user
- The Fernet encryption key has a public default value that must be changed before production use. [Production install](03-install-production.md) → step 2. Generate the encryption key
- `baseUrl` must equal the externally reachable address, or QR/mobile capture silently fails. [Production install](03-install-production.md) -> step 4. Configure the address and HTTPS
- Document Reader's Session API must be enabled for IDV integration to work. [Integrations](04-integrations.md) → Document Reader — explicitly says Session API is off by default and workflows requiring document reading fail without it.
- Session data is kept forever unless retention (`cleanSessions`) is explicitly configured. [Configuration](05-configuration.md#scheduled-clean-up-jobs) -> Scheduled clean-up jobs
- Most Scheduler cron expressions are 6-field (seconds first), not standard 5-field cron. [Configuration](05-configuration.md#scheduled-clean-up-jobs) -> Scheduled clean-up jobs

## Open question for the platform team

`DONE`

[Sign-in methods](06-auth-and-users.md#sign-in-methods)

What does `basicAuth.enabled: false` actually do — is local login fully disabled, and is there a
recovery path if SSO is misconfigured? Not documented anywhere; no known deployment runs it `false`.
Get an answer, then document it.

## Timing: wait for the `backoffice`/`frontoffice` rename

The next chart version renames the `api` component to `backoffice` and adds an optional
`frontoffice` component. Update these pages **when that chart is promoted and published**, not
before — until then, `api.*` is correct. At that point: replace `api.*` with `backoffice.*`, add a
frontoffice section, and note it's a breaking change for upgraders.
