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
{{- if .Values.enableComponentLabels }}
app.kubernetes.io/component: docreader
{{- end }}
{{- if .Values.commonLabels }}
{{- toYaml .Values.commonLabels | nindent 0 }}
{{- end }}
{{- end }}

{{/* Selector labels for migration job */}}
{{- define "docreader.migrationSelectorLabels" -}}
app.kubernetes.io/name: {{ include "docreader.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.enableComponentLabels }}
app.kubernetes.io/component: db-migration
{{- end }}
{{- if .Values.commonLabels }}
{{- toYaml .Values.commonLabels | nindent 0 }}
{{- end }}
{{- end }}

{{/* Create the name of the service account to use */}}
{{- define "docreader.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "docreader.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}

{{/* Config map name */}}
{{- define "docreader.config.name" -}}
{{ (printf "%s-docreader-config" .Release.Name) }}
{{- end }}

{{/* Docreader license secret name */}}
{{- define "docreader.license.secret" -}}
{{ default (printf "%s-license" .Release.Name) .Values.licenseSecretName }}
{{- end }}

{{/* Docreader certificates secret name */}}
{{- define "docreader.certificates.secret" -}}
{{ default (printf "%s-certificates" .Release.Name) .Values.config.service.webServer.ssl.certificatesSecretName }}
{{- end }}

{{/* Docreader AWS Credentials secret name */}}
{{- define "docreader.aws.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "s3") .Values.config.service.storage.s3.awsCredentialsSecretName -}}
{{ default (printf "%s-aws-credentials" .Release.Name) .Values.config.service.storage.s3.awsCredentialsSecretName }}
{{- end }}
{{- end }}

{{/* Docreader GCS Credentials secret name */}}
{{- define "docreader.gcs.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "gcs") .Values.config.service.storage.gcs.gcsKeyJsonSecretName -}}
{{ default (printf "%s-gcs-credentials" .Release.Name) .Values.config.service.storage.gcs.gcsKeyJsonSecretName }}
{{- end }}
{{- end }}

{{/* Docreader Azure Storage Connection String secret name */}}
{{- define "docreader.az.credentials.secret" -}}
{{- if and (eq .Values.config.service.storage.type "az") .Values.config.service.storage.az.connectionStringSecretName -}}
{{ default (printf "%s-az-credentials" .Release.Name) .Values.config.service.storage.az.connectionStringSecretName }}
{{- end }}
{{- end }}

{{/* Docreader Database Connection String secret name */}}
{{- define "docreader.db.credentials.secret" -}}
{{- if .Values.config.service.database.connectionStringSecretName -}}
{{ default (printf "%s-db-credentials" .Release.Name) .Values.config.service.database.connectionStringSecretName }}
{{- end }}
{{- end }}

{{/* PostgreSQL host */}}
{{- define "docreader.postgresql" -}}
{{ default (printf "%s-postgresql" .Release.Name) }}
{{- end }}

{{/* DB Migrations Job Name */}}
{{- define "docreader.migration" -}}
{{ default (printf "%s-db-migration-job" .Release.Name) }}
{{- end }}

{{/* User defined docreader environment variables */}}
{{- define "docreader.envs" -}}
  {{- range $i, $config := .Values.env }}
  - name: {{ $config.name }}
    value: {{ $config.value | quote }}
  {{- end }}
{{- end }}

{{/* Docreader processing results volume claim */}}
{{- define "docreader.processing.results.pvc" -}}
{{- if .Values.processing.results.persistence.existingClaim -}}
{{ .Values.processing.results.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-processing-results
{{- end -}}
{{- end -}}

{{/* Docreader Session API transactions volume claim */}}
{{- define "docreader.sessionApi.transactions.pvc" -}}
{{- if .Values.config.service.sessionApi.transactions.persistence.existingClaim -}}
{{ .Values.config.service.sessionApi.transactions.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-session-api-transactions
{{- end -}}
{{- end -}}

{{/* SDK Error Log volume claim */}}
{{- define "docreader.sdkErrorLog.pvc" -}}
{{- if .Values.config.service.sdkErrorLog.persistence.existingClaim -}}
{{ .Values.config.service.sdkErrorLog.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-sdk-error-log
{{- end -}}
{{- end -}}

{{/* Docreader RFID PKD PA volume claim */}}
{{- define "docreader.rfid.pkd.pvc" -}}
{{- if .Values.config.sdk.rfid.persistence.existingClaim -}}
{{ .Values.config.sdk.rfid.persistence.existingClaim }}
{{- else -}}
{{ .Release.Name }}-rfid-pkd-pa
{{- end -}}
{{- end -}}
