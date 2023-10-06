{{- define "faceapi.config" -}}
# General
{{- if .Values.general.bind }}
FACEAPI_BIND="{{ .Values.general.bind }}"
{{- end }}
FACEAPI_WORKERS="{{ .Values.general.workers }}"
FACEAPI_BACKLOG="{{ .Values.general.backlog }}"
FACEAPI_TIMEOUT="{{ .Values.general.timeout }}"
FACEAPI_ENABLE_DEMO_WEB_APP="{{ .Values.general.demoSite }}"
{{- if .Values.general.licenseUrl }}
FACEAPI_LIC_URL="{{ .Values.general.licenseUrl }}"
{{- end }}
{{- if .Values.general.httpsProxy }}
FACEAPI_HTTPS_PROXY="{{ .Values.general.httpsProxy }}"
{{- end }}
{{- if .Values.general.returnSystemInfo }}
REGULA_RETURN_SYSTEMINFO="{{ .Values.general.returnSystemInfo }}"
{{- end }}

# HTTPS
FACEAPI_HTTPS="{{ .Values.https.enabled }}"

{{- if .Values.cors.origins }}
# CORS ORIGINS
FACEAPI_CORS_ORIGINS="{{ .Values.cors.origins }}"
{{- end }}
{{- if .Values.cors.methods }}
# CORS METHODS
FACEAPI_CORS_METHODS="{{ .Values.cors.methods }}"
{{- end }}
{{- if .Values.cors.headers }}
# CORS HEADERS
FACEAPI_CORS_HEADERS="{{ .Values.cors.headers }}"
{{- end }}

# Logs
FACEAPI_LOGS_ACCESS_FILE="{{ .Values.logs.type.accessLog }}"
FACEAPI_LOGS_APP_FILE="{{ .Values.logs.type.appLog }}"
FACEAPI_PROCESS_RESULTS_LOG_FILE="{{ .Values.logs.type.processLog.enabled }}"
FACEAPI_LOGS_PROCESS_SAVE_RESULT="{{ .Values.logs.type.processLog.saveResult }}"
FACEAPI_LOGS_LEVEL="{{ .Values.logs.level }}"
FACEAPI_LOGS_FORMATTER="{{ .Values.logs.format }}"

# Prometheus
FACEAPI_ENABLE_PROMETHEUS_METRICS="{{ .Values.metrics.enabled }}"

{{- if .Values.identification.enabled }}
# Identification
FACEAPI_ENABLE_IDENTIFICATION="true"
{{- if .Values.liveness.enabled }}

# Liveness
FACEAPI_LIVENESS_GEN_2="true"
FACEAPI_LIVENESS_HIDE_METADATA="{{ .Values.liveness.hideMetadata }}"
{{- end }}

# Milvus
FACEAPI_MILVUS_HOST="{{ template "faceapi.identification.milvus_host" . }}"
FACEAPI_MILVUS_PORT="{{ default 19530 .Values.identification.milvusPort }}"

{{- if .Values.milvus.externalS3.enabled }}
# Milvus. External Storage
{{- if .Values.milvus.externalS3.useSSL }}
FACEAPI_STORAGE_ENDPOINT="https://{{ .Values.milvus.externalS3.host }}:{{ .Values.milvus.externalS3.port }}"
{{- else }}
FACEAPI_STORAGE_ENDPOINT="http://{{ .Values.milvus.externalS3.host }}:{{ .Values.milvus.externalS3.port }}"
{{- end }}
FACEAPI_STORAGE_ACCESS_KEY="{{ default .Values.milvus.externalS3.accessKey .Values.storage.accessKey }}"
FACEAPI_STORAGE_SECRET_KEY="{{ default .Values.milvus.externalS3.secretKey .Values.storage.secretKey }}"
{{- else }}

# Storage
FACEAPI_STORAGE_ENDPOINT="{{ template "faceapi.storage.endpoint" . }}"
FACEAPI_STORAGE_ACCESS_KEY="{{ default "minioadmin" .Values.storage.accessKey }}"
FACEAPI_STORAGE_SECRET_KEY="{{ default "minioadmin" .Values.storage.secretKey }}"
{{- end }}
FACEAPI_STORAGE_REGION="{{ default "us-east-1" .Values.storage.region }}"
FACEAPI_STORAGE_PERSON_BUCKET_NAME="{{ default "faceapi-person" .Values.storage.personBucketName }}"
FACEAPI_STORAGE_SESSION_BUCKET_NAME="{{ default "faceapi-session" .Values.storage.sessionBucketName }}"
{{- end }}

{{- if and .Values.liveness.enabled (not .Values.identification.enabled) }}
# Liveness
FACEAPI_LIVENESS_GEN_2="true"
FACEAPI_LIVENESS_HIDE_METADATA="{{ .Values.liveness.hideMetadata }}"

# Storage
FACEAPI_STORAGE_ENDPOINT="{{ template "faceapi.storage.endpoint" . }}"
FACEAPI_STORAGE_ACCESS_KEY="{{ default "minioadmin" .Values.storage.accessKey }}"
FACEAPI_STORAGE_SECRET_KEY="{{ default "minioadmin" .Values.storage.secretKey }}"
FACEAPI_STORAGE_REGION="{{ default "us-east-1" .Values.storage.region }}"
FACEAPI_STORAGE_SESSION_BUCKET_NAME="{{ default "faceapi-session" .Values.storage.sessionBucketName }}"
{{- end }}


{{- if and .Values.externalPostgreSQL (not .Values.postgresql.enabled) }}
# PostgreSQL
## Please mind if externalPostgreSQLSecret value is set, it overrides any other PostgreSQL related values
FACEAPI_SQL_URL="{{ .Values.externalPostgreSQL }}"
{{- else if .Values.postgresql.enabled }}
FACEAPI_SQL_URL="postgresql://{{ .Values.postgresql.global.postgresql.auth.username }}:{{ .Values.postgresql.global.postgresql.auth.password }}@{{ template "faceapi.postgresql" . }}:5432/{{ .Values.postgresql.global.postgresql.auth.database }}"
{{- end }}

{{- end }}