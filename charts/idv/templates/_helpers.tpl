{{/*
Expand the name of the chart.
*/}}
{{- define "idv.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "idv.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "idv.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "idv.labels" -}}
app: idv
helm.sh/chart: {{ include "idv.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Backoffice labels
*/}}
{{- define "idv.backoffice.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.backoffice.selectorLabels" . }}
{{- end }}

{{/*
Backoffice Selector labels
*/}}
{{- define "idv.backoffice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-backoffice
app.kubernetes.io/component: backoffice
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Frontoffice labels
*/}}
{{- define "idv.frontoffice.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.frontoffice.selectorLabels" . }}
{{- end }}

{{/*
Frontoffice Selector labels
*/}}
{{- define "idv.frontoffice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-frontoffice
app.kubernetes.io/component: frontoffice
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Device Gateway labels
*/}}
{{- define "idv.deviceGateway.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.deviceGateway.selectorLabels" . }}
{{- end }}

{{/*
Device Gateway Selector labels
*/}}
{{- define "idv.deviceGateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-device-gateway
app.kubernetes.io/component: device-gateway
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Audit labels
*/}}
{{- define "idv.audit.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.audit.selectorLabels" . }}
{{- end }}

{{/*
Audit Selector labels
*/}}
{{- define "idv.audit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-audit
app.kubernetes.io/component: audit
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Indexer labels
*/}}
{{- define "idv.indexer.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.indexer.selectorLabels" . }}
{{- end }}

{{/*
Indexer Selector labels
*/}}
{{- define "idv.indexer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-indexer
app.kubernetes.io/component: indexer
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Scheduler labels
*/}}
{{- define "idv.scheduler.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.scheduler.selectorLabels" . }}
{{- end }}

{{/*
Scheduler Selector labels
*/}}
{{- define "idv.scheduler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-scheduler
app.kubernetes.io/component: scheduler
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Workflow labels
*/}}
{{- define "idv.workflow.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.workflow.selectorLabels" . }}
{{- end }}

{{/*
Workflow Selector labels
*/}}
{{- define "idv.workflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-workflow
app.kubernetes.io/component: workflow
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
GCS credentials secret name
*/}}
{{- define "idv.gcs.credentials.secret" -}}
{{- if and (eq .Values.config.storage.type "gcs") .Values.config.storage.gcs.gcsKeyJsonSecretName -}}
{{ default (printf "%s-gcs-credentials" .Release.Name) .Values.config.storage.gcs.gcsKeyJsonSecretName }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "idv.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "idv.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* prometheus-statsd-exporter host */}}
{{- define "idv.statsd" -}}
{{ default (printf "%s-statsd" .Release.Name ) }}
{{- end }}

{{/* RabbitMQ host */}}
{{- define "idv.rabbitmq" -}}
{{ default (printf "%s-rabbitmq" .Release.Name) }}
{{- end }}

{{/* Minio host */}}
{{- define "idv.minio" -}}
{{ default (printf "%s-minio" .Release.Name) }}
{{- end }}

{{- define "idv.minioInitContainer" -}}
{{- if .Values.minio.enabled }}
initContainers:
  - name: init-minio-bucket
    image: "{{ .Values.minio.clientImage.registry | default "docker.io" }}/{{ .Values.minio.clientImage.repository }}:{{ .Values.minio.clientImage.tag }}"
    imagePullPolicy: {{ .Values.minio.clientImage.pullPolicy | default "IfNotPresent" }}
    # `bash`, not `sh`: /bin/sh is dash in this image and the script below uses `set -o pipefail`,
    # which dash does not support.
    command: ["bash", "-c"]
    args:
      - |
        set -euo pipefail
        until mc alias set myminio http://{{ template "idv.minio" . }}:9000 {{ .Values.minio.auth.rootUser | default "user" | quote }} {{ .Values.minio.auth.rootPassword | default "password123" | quote }}; do sleep 5; done
        {{- range (include "idv.storage.minioBuckets" . | fromYamlArray) }}
        mc mb myminio/{{ . }} --ignore-existing
        {{- end }}
        echo "Buckets ready"
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
    securityContext: {{- toYaml .Values.securityContext | nindent 6 }}
{{- end }}
{{- end }}

{{/*
TLS trusted CA bundle: file path of the mounted bundle.
*/}}
{{- define "idv.tls.bundleFile" -}}
{{- printf "%s/%s" .Values.tls.trustedCABundle.mountPath .Values.tls.trustedCABundle.key -}}
{{- end -}}

{{/*
Extra pod volumes: optional trusted-CA bundle ConfigMap + user-provided extraVolumes.
Backward compatible: renders nothing unless tls.trustedCABundle.configMapName or extraVolumes is set.
*/}}
{{- define "idv.extraVolumes" -}}
{{- if .Values.tls.trustedCABundle.configMapName }}
- name: regula-ca-bundle
  configMap:
    name: {{ .Values.tls.trustedCABundle.configMapName }}
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Extra container volumeMounts: CA bundle as a directory (for clients that take an explicit CA
path, e.g. MongoDB tlsCAFile) plus per-CA-store file overlays (for clients that read a bundled
CA store such as certifi/botocore or the system trust store), then user extraVolumeMounts.
*/}}
{{- define "idv.extraVolumeMounts" -}}
{{- if .Values.tls.trustedCABundle.configMapName }}
- name: regula-ca-bundle
  mountPath: {{ .Values.tls.trustedCABundle.mountPath }}
  readOnly: true
{{- range .Values.tls.trustedCABundle.caStorePaths }}
- name: regula-ca-bundle
  mountPath: {{ . }}
  subPath: {{ $.Values.tls.trustedCABundle.key }}
  readOnly: true
{{- end }}
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Full container env: when a trusted-CA bundle is configured, prepend the standard CA-bundle
environment variables (honored by clients that read them), then the user-provided env.
*/}}
{{- define "idv.fullEnv" -}}
{{- $env := .Values.env | default (list) -}}
{{- if .Values.tls.trustedCABundle.configMapName -}}
{{- $f := include "idv.tls.bundleFile" . -}}
{{- $env = concat (list (dict "name" "SSL_CERT_FILE" "value" $f) (dict "name" "REQUESTS_CA_BUNDLE" "value" $f) (dict "name" "AWS_CA_BUNDLE" "value" $f)) $env -}}
{{- end -}}
{{- toYaml $env -}}
{{- end -}}

{{/*
Reports the state of the Fernet encryption key, for the install warning in NOTES.txt.
An IDV_CONFIG__FERNETKEY entry in the top-level `env` list counts as properly set,
since that overrides the config file at runtime.

Returns:
  "default" - the chart's publicly published default key is in use
  "missing" - no key supplied at all
  ""        - a key is set properly
*/}}
{{- define "idv.fernetKeyState" -}}
{{- $publicDefault := "tton53xJw0QV6vfaOTNRP_YGnPc76ZJkXFdVFZSnaKQ=" -}}
{{- $key := .Values.config.fernetKey | default "" -}}
{{- $overridden := false -}}
{{- range (.Values.env | default (list)) -}}
{{- if eq (.name | default "") "IDV_CONFIG__FERNETKEY" -}}
{{- $overridden = true -}}
{{- end -}}
{{- end -}}
{{- if not $overridden -}}
{{- if eq $key $publicDefault -}}
default
{{- else if eq $key "" -}}
missing
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Backward compatibility for the `api` -> `backoffice` rename (IDV 3.10). Deprecated.
Values under the old keys (top-level `api:` and `config.services.api`) are laid over the
`backoffice` defaults. Neither old key exists in values.yaml, so anything there was set by the
user. Idempotent: include it at the top of every template that reads backoffice values.
*/}}
{{- define "idv.compat" -}}
{{- if .Values.api }}
{{- $_ := mergeOverwrite .Values.backoffice .Values.api }}
{{- end }}
{{- if (.Values.config.services).api }}
{{- $_ := mergeOverwrite .Values.config.services.backoffice .Values.config.services.api }}
{{- end }}
{{- end }}

{{/*
Backward compatibility for the per-entity storage restructure (IDV 3.10). Deprecated.
Before the restructure, each storage entity carried its own `location.bucket` (s3/gcs) and the
removed `location.folder`. The new values keep only `location.prefix`, with a single backend-level
`s3.bucket` / `gcs.bucket`. Neither `location.bucket` nor `location.folder` exists in values.yaml,
so if a user's merged values still carry them, they came from a pre-3.10 config.

The 3.10 application still honors the old per-entity layout (removed only in app 5.0), so when a
user supplied the old keys we render them straight back into the app config. This preserves their
data path instead of silently falling back to the default `s3.bucket` (`idv-bucket`).

Call with a dict: {{ include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.sessions) }}
Renders nothing for new-style values.
*/}}
{{- define "idv.storage.legacyLocation" -}}
{{- $loc := (.entity).location | default dict -}}
{{- $lines := list -}}
{{- if hasKey $loc "bucket" -}}
{{- $lines = append $lines (printf "bucket: %s" (quote $loc.bucket)) -}}
{{- end -}}
{{- if hasKey $loc "folder" -}}
{{- $lines = append $lines (printf "folder: %s" (quote $loc.folder)) -}}
{{- end -}}
{{- join "\n" $lines -}}
{{- end -}}

{{/*
True when any storage entity still carries the pre-3.10 `location.bucket` or `location.folder`
keys, i.e. the user has a legacy storage config. Used for the DEPRECATED note in NOTES.txt.
*/}}
{{- define "idv.storage.isLegacy" -}}
{{- $legacy := false -}}
{{- range $name, $entity := .Values.config.storage -}}
{{- if kindIs "map" $entity -}}
{{- $loc := $entity.location | default dict -}}
{{- if or (hasKey $loc "bucket") (hasKey $loc "folder") -}}
{{- $legacy = true -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $legacy }}true{{ end }}
{{- end -}}

{{/*
True when any storage entity carries a per-entity `location.bucket` (the pre-3.10 s3/gcs layout).
Scoped to `bucket` only — not `folder` — because `folder` is orthogonal to bucket precedence and
Azure never had a per-entity container to fall back to.
*/}}
{{- define "idv.storage.hasLegacyBucket" -}}
{{- $found := false -}}
{{- range $name, $entity := .Values.config.storage -}}
{{- if kindIs "map" $entity -}}
{{- if hasKey ($entity.location | default dict) "bucket" -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $found }}true{{ end }}
{{- end -}}

{{/*
Backend-level S3/GCS bucket value with the 3.10 precedence rule applied.

The application uses the backend-level `s3.bucket`/`gcs.bucket` when it is non-empty, and only
falls back to the per-entity `location.bucket` when it is empty. So for a legacy config (per-entity
buckets present), we must render the backend value as EMPTY — otherwise the non-empty default
(`idv-bucket`) would override every entity's real bucket and silently redirect their data.

Only applies to s3/gcs. Azure has no per-entity container fallback, so `az.container` is rendered
verbatim elsewhere (never suppressed).

Returns the configured backend value for a new-style config, or "" when per-entity buckets exist.
*/}}
{{- define "idv.storage.backendBucket" -}}
{{- $val := .value | default "" -}}
{{- if eq (include "idv.storage.hasLegacyBucket" .ctx) "true" -}}
{{- else -}}
{{- $val -}}
{{- end -}}
{{- end -}}

{{/*
The set of buckets the bundled MinIO init container must create (dev/test only), as a YAML array.

Mirrors the bucket the app will actually use (see idv.storage.backendBucket precedence):
- new-style config -> the single backend `config.storage.s3.bucket`
- legacy config (per-entity buckets) -> the de-duplicated set of per-entity `location.bucket`s,
  since the backend bucket is rendered empty and the app uses the per-entity ones.
*/}}
{{- define "idv.storage.minioBuckets" -}}
{{- if eq (include "idv.storage.hasLegacyBucket" .) "true" -}}
{{- $buckets := list -}}
{{- range $name, $entity := .Values.config.storage -}}
{{- if kindIs "map" $entity -}}
{{- $b := ($entity.location | default dict).bucket -}}
{{- if $b -}}
{{- $buckets = append $buckets $b -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $buckets | uniq | toYaml -}}
{{- else -}}
{{- list .Values.config.storage.s3.bucket | toYaml -}}
{{- end -}}
{{- end -}}
