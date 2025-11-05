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
