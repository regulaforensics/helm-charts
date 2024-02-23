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
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}
{{- end }}

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

{{/* Selector labels */}}
{{- define "faceapi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "faceapi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Create the name of the service account to use */}}
{{- define "faceapi.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default "faceapi" .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* Config map name */}}
{{- define "faceapi.config.name" -}}
{{ (printf "%s-faceapi-config" .Release.Name) }}
{{- end }}

{{/* Faceapi license secret name */}}
{{- define "faceapi.license.secret" -}}
{{ default (printf "%s-license" .Release.Name) .Values.licenseSecretName }}
{{- end }}

{{/* Faceapi certificates secret name */}}
{{- define "faceapi.certificates.secret" -}}
{{ default (printf "%s-certificates" .Release.Name) .Values.config.service.webServer.ssl.certificatesSecretName }}
{{- end }}

{{/* Faceapi AWS Credentials secret name */}}
{{- define "faceapi.aws.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "s3") .Values.config.service.storage.s3.awsCredentialsSecretName -}}
{{ default (printf "%s-aws-credentials" .Release.Name) .Values.config.service.storage.s3.awsCredentialsSecretName }}
{{- end }}
{{- end }}

{{/* Faceapi GCS Credentials secret name */}}
{{- define "faceapi.gcs.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "gcs") .Values.config.service.storage.gcs.gcsKeyJsonSecretName -}}
{{ default (printf "%s-gcs-credentials" .Release.Name) .Values.config.service.storage.gcs.gcsKeyJsonSecretName }}
{{- end }}
{{- end }}

{{/* Faceapi Azure Storage Connection String secret name */}}
{{- define "faceapi.az.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "az") .Values.config.service.storage.az.connectionStringSecretName -}}
{{ default (printf "%s-az-credentials" .Release.Name) .Values.config.service.storage.az.connectionStringSecretName }}
{{- end }}
{{- end }}

{{/* Faceapi Database Connection String secret name */}}
{{- define "faceapi.db.credentials.secret" -}}
{{- if .Values.config.service.database.connectionStringSecretName -}}
{{ default (printf "%s-db-credentials" .Release.Name) .Values.config.service.database.connectionStringSecretName }}
{{- end }}
{{- end }}

{{/* Milvus endpoint */}}
{{- define "faceapi.milvus" -}}
{{ default (printf "%s-milvus:19530" .Release.Name) }}
{{- end }}

{{/* PostgreSQL host */}}
{{- define "faceapi.postgresql" -}}
{{ default (printf "%s-postgresql" .Release.Name) }}
{{- end }}

{{/* User defined faceapi environment variables */}}
{{- define "faceapi.envs" -}}
  {{- range $i, $config := .Values.env }}
  - name: {{ $config.name }}
    value: {{ $config.value | quote }}
  {{- end }}
{{- end }}

{{/* Faceapi detect-match/results existing volume claim */}}
{{- define "faceapi.detectmatch.results.pvc" -}}
{{- if .Values.config.service.detectMatch.results.persistence.existingClaim -}}
{{ .Values.config.service.detectMatch.results.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-detectmatch-results
{{- end -}}
{{- end -}}

{{/* Faceapi liveness/sessions existing volume claim */}}
{{- define "faceapi.liveness.sessions.pvc" -}}
{{- if .Values.config.service.liveness.sessions.persistence.existingClaim -}}
{{ .Values.config.service.liveness.sessions.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-liveness-sessions
{{- end -}}
{{- end -}}

{{/* Faceapi search/persons existing volume claim */}}
{{- define "faceapi.search.persons.pvc" -}}
{{- if .Values.config.service.search.persons.persistence.existingClaim -}}
{{ .Values.config.service.search.persons.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-search-persons
{{- end -}}
{{- end -}}
