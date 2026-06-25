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
API labels
*/}}
{{- define "idv.api.labels" -}}
{{ include "idv.labels" . }}
{{ include "idv.api.selectorLabels" . }}
{{- end }}

{{/*
API Selector labels
*/}}
{{- define "idv.api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "idv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}-api
app.kubernetes.io/component: api
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
    image: "{{ .Values.minio.mcImage.repository }}:{{ .Values.minio.mcImage.tag }}"
    imagePullPolicy: {{ .Values.minio.mcImage.pullPolicy }}
    command: ["sh", "-c"]
    args:
      - |
        set -euo pipefail
        until mc alias set myminio http://{{ template "idv.minio" . }}:9000 {{ .Values.minio.rootUser | default "user" | quote }} {{ .Values.minio.rootPassword | default "password123" | quote }}; do sleep 5; done
        mc mb myminio/{{ .Values.config.storage.sessions.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.persons.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.workflows.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.userFiles.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.locales.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.assets.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.tempFiles.location.bucket }} --ignore-existing
        mc mb myminio/{{ .Values.config.storage.banlists.location.bucket }} --ignore-existing
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
