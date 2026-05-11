# helm-charts — Public Release Repository

## Purpose

This is the **public** Helm charts repository for Regula Forensics. It hosts production-ready, versioned Helm charts published via GitHub Pages using `chart-releaser`. Charts land here only after being tested and validated in the private `helm-test` repo.

## Charts

| Chart | Description | Key Dependencies |
|---|---|---|
| `docreader` | Identity document data extraction | PostgreSQL (optional) |
| `faceapi` | Face recognition / biometric matching | PostgreSQL, Milvus (optional) |
| `idv` | Identity Verification Platform (multi-component) | MongoDB, RabbitMQ, MinIO, OpenSearch, Prometheus statsd |

> `api-gateway` lives only in `helm-test` (internal/experimental). Do not add it here without explicit instruction.

## Workflow: Promoting a Chart from helm-test

When releasing a new app version, copy the chart from `helm-test` to this repo following these steps:

1. Copy the entire `charts/<name>/` directory from `helm-test` into this repo.
2. Update `Chart.yaml`:
   - Set `appVersion` to the real release tag (e.g., `9.4.319820.2195`), **not** `nightly` or `develop`.
   - Bump `version` (chart version) following semver — patch for fixes, minor for new features, major for breaking changes.
3. Ensure `README.md` reflects any new values or changed defaults.
4. Open a PR against `main`. The CI pipeline will:
   - Lint the chart (`ct lint`)
   - Verify the chart version was incremented (`chart-version.yaml` workflow)
   - Install the chart in a `kind` cluster with a real license secret
5. Merge to `main` triggers `chart-releaser`, which packages and publishes the chart.

## Chart Version Rules

- `version` in `Chart.yaml` must always be **higher** than the current `main` branch value — the CI enforces this.
- Format: `MAJOR.MINOR.PATCH` (semver).
- `appVersion` must be the exact application image tag being released — never `nightly` or `develop`.
- Do not use `check-version-increment: true` in `ct.yaml`; versioning is managed manually.

## File & Template Conventions

```
charts/<name>/
├── Chart.yaml          # apiVersion: v2, semver version, real appVersion
├── README.md           # Installation guide with license secret instructions
├── values.yaml         # Fully documented parameters
└── templates/
    ├── _helpers.tpl    # fullname, labels, selectorLabels macros
    ├── deployment.yaml # Must include checksum/config annotation
    ├── configmap.yaml  # Rendered from config.tpl
    ├── config.tpl      # Service config template
    ├── service.yaml
    ├── ingress.yaml / route.yaml
    ├── hpa.yaml, keda-hpa.yaml
    └── networkpolicy.yaml, servicemonitor.yaml, role.yaml, rolebinding.yaml, serviceaccount.yaml
```

### Critical rules
- **Always keep** `checksum/config: {{ include "<chart>.configmap" . | sha256sum }}` in deployment annotations — this triggers rolling restarts on ConfigMap changes.
- Labels must follow `app.kubernetes.io/*` conventions: `name`, `version`, `managed-by`, `instance`.
- `idv` uses per-component label helpers (e.g., `idv.api.labels`, `idv.workflow.selectorLabels`) — do not flatten them.
- License secret is **never** bundled in the chart; it is created by the operator before install (`licenseSecretName` value).

## CI/CD

- **PR → main**: runs lint + chart-version check + kind cluster install test.
- **Push to main**: `chart-releaser` packages and publishes to GitHub Pages.
- Helm version in CI: `v3.18.2` (see `lint-test.yml`).
- License for CI tests is stored as `secrets.REGULA_LICENSE` (base64-encoded).

## What NOT to Do

- Do not commit `appVersion: nightly` or `appVersion: develop` — these are test-only values.
- Do not skip the version bump — CI will fail the PR.
- Do not add secrets or license file contents to the chart or values.
- Do not push directly to `main` — always use a PR.
