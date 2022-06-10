{{- define "docreader.config" -}}
# General
{{- if .Values.general.bind }}
DOCREADER_BIND="{{ .Values.general.bind }}"
{{- end }}
DOCREADER_WORKERS="{{ .Values.general.workers }}"
DOCREADER_BACKLOG="{{ .Values.general.backlog }}"
DOCREADER_TIMEOUT="{{ .Values.general.timeout }}"
DOCREADER_ENABLE_DEMO_WEB_APP="{{ .Values.general.demoSite }}"
{{- if .Values.general.licenseUrl }}
DOCREADER_LIC_URL="{{ .Values.general.licenseUrl }}"
{{- end }}
{{- if .Values.general.httpsProxy }}
DOCREADER_HTTPS_PROXY="{{ .Values.general.httpsProxy }}"
{{- end }}

{{- if and .Values.https.enabled }}
# HTTPS
DOCREADER_HTTPS="{{ .Values.https.enabled }}"
{{- end }}

# CORS
{{- if .Values.cors.origins }}
DOCREADER_CORS_ORIGINS="{{ .Values.cors.origins }}"
{{- end }}
{{- if .Values.cors.methods }}
DOCREADER_CORS_METHODS="{{ .Values.cors.methods }}"
{{- end }}
{{- if .Values.cors.headers }}
DOCREADER_CORS_HEADERS="{{ .Values.cors.headers }}"
{{- end }}

# Logs
DOCREADER_LOGS_ACCESS_FILE="{{ .Values.logs.type.accessLog }}"
DOCREADER_LOGS_APP_FILE="{{ .Values.logs.type.appLog }}"
DOCREADER_PROCESS_RESULTS_LOG_FILE="{{ .Values.logs.type.processLog.enabled }}"
DOCREADER_LOGS_PROCESS_SAVE_RESULT="{{ .Values.logs.type.processLog.saveResult }}"
DOCREADER_LOGS_LEVEL="{{ .Values.logs.level }}"
DOCREADER_LOGS_FORMATTER="{{ .Values.logs.format }}"

# RFID PKD PA
DOCREADER_RFID_PKD_PA="{{ .Values.rfidpkd.enabled }}"
{{- end }}
