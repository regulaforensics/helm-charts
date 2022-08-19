{{/* Expand the name of the chart. */}}
{{- define "docreader.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "docreader.fullname" -}}
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


{{/* Create chart name and version as used by the chart label. */}}
{{- define "docreader.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/* Common labels */}}
{{- define "docreader.labels" -}}
helm.sh/chart: {{ include "docreader.chart" . }}
{{ include "docreader.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/* Selector labels */}}
{{- define "docreader.selectorLabels" -}}
app.kubernetes.io/name: {{ include "docreader.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/* Docreader license secret name */}}
{{- define "license_secret" -}}
{{ default (printf "%s-license" .Release.Name) .Values.licenseSecretName }}
{{- end }}


{{/* Docreader certificates secret name */}}
{{- define "certificate_secret" -}}
{{- if .Values.https.certificatesSecretName -}}
  {{ default (printf "%s-certificates" .Release.Name) .Values.https.certificatesSecretName }}
{{- end }}
{{- end }}


{{/* Config map name */}}
{{- define "config" -}}
{{ (printf "%s-config" .Release.Name) }}
{{- end }}

{{/* Minio endpoint */}}
{{- define "chipVerification.storage_endpoint" -}}
{{ default (printf "%s-minio:9000" .Release.Name) }}
{{- end }}

{{/* Minio bucket name */}}
{{- define "minio.bucket_name" -}}
{{- range .Values.minio.buckets -}}
{{ .name }}
{{- end }}
{{- end }}


{{/* User defined docreader environment variables */}}
{{- define "docreader_envs" -}}
  {{- range $i, $config := .Values.env }}
  - name: {{ $config.name }}
    value: {{ $config.value | quote }}
  {{- end }}
{{- end }}


{{/* Docreader logs existing volume claim */}}
{{- define "logs_volume_claim" -}}
{{- if .Values.logs.persistence.existingClaim -}}
{{ .Values.logs.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-logs
{{- end -}}
{{- end -}}


{{/* Docreader rfidpkd existing volume claim */}}
{{- define "rfidpkd_volume_claim" -}}
{{- if .Values.rfidpkd.existingClaim -}}
{{ .Values.rfidpkd.existingClaim }}
{{- end -}}
{{- end -}}
