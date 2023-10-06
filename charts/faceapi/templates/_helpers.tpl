{{/* Expand the name of the chart. */}}
{{- define "faceapi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "faceapi.fullname" -}}
{{- if .Values.fullnameOverride -}}
  {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
  {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/* Create chart name and version as used by the chart label. */}}
{{- define "faceapi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/* Common labels */}}
{{- define "faceapi.labels" -}}
helm.sh/chart: {{ include "faceapi.chart" . }}
{{ include "faceapi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/* matchLabels */}}
{{- define "faceapi.matchLabels" -}}
app.kubernetes.io/name: {{ include "faceapi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/* Selector labels */}}
{{- define "faceapi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "faceapi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/* Version name */}}
{{- define "version" -}}
{{- if .Values.version | default "cpu" | lower | regexMatch "^(cpu|gpu)$" -}}
  {{ .Values.version | default "cpu" | lower }}
{{- else}}
  {{ required (printf "Incorrect 'version': %s. Possible value: cpu or gpu" .Values.version) nil }}
{{- end -}}
{{- end -}}


{{/* faceapi license secret name */}}
{{- define "faceapi.license.secret" -}}
{{ default (printf "%s-license" .Release.Name) .Values.licenseSecretName }}
{{- end }}


{{/* faceapi certificates secret name */}}
{{- define "faceapi.certificate.secret" -}}
{{ default (printf "%s-certificates" .Release.Name) .Values.https.certificatesSecretName }}
{{- end }}


{{/* Config map name */}}
{{- define "faceapi.config.name" -}}
{{ (printf "%s-faceapi-config" .Release.Name) }}
{{- end }}


{{/* User defined faceapi environment variables */}}
{{- define "faceapi.envs" -}}
  {{- range $i, $config := .Values.env }}
  - name: {{ $config.name }}
    value: {{ $config.value | quote }}
  {{- end }}
{{- end }}


{{/* Minio/S3 Storage endpoint */}}
{{- define "faceapi.storage.endpoint" -}}
{{ default (printf "http://%s-minio:9000" .Release.Name) .Values.storage.endpoint }}
{{- end }}


{{/* Milvus host */}}
{{- define "faceapi.identification.milvus_host" -}}
{{ default (printf "%s-milvus" .Release.Name) .Values.identification.milvusHost }}
{{- end }}


{{/* PostgreSQL host */}}
{{- define "faceapi.postgresql" -}}
{{ default (printf "%s-postgresql" .Release.Name) }}
{{- end }}


{{- define "faceapi.postgresql.secret" -}}
{{- if .Values.externalPostgreSQLSecret }}
- name: FACEAPI_SQL_URL
  valueFrom:
    secretKeyRef:
      {{- .Values.externalPostgreSQLSecret | toYaml | nindent 6 }}
{{- end }}
{{- end }}


{{/* Face-API logs PVC */}}
{{- define "faceapi.logs.pvc" -}}
{{- if .Values.logs.persistence.existingClaim -}}
  {{ .Values.logs.persistence.existingClaim }}
{{- else -}}
  {{ .Release.Name }}-logs
{{- end -}}
{{- end -}}