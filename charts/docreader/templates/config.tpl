{{- define "docreader.config" -}}
sdk:
  systemInfo:
    returnSystemInfo: {{ .Values.config.sdk.systemInfo.returnSystemInfo }}

  rfid:
    enabled: {{ .Values.config.sdk.rfid.enabled }}
    {{- if .Values.config.sdk.rfid.enabled }}
    PKD_PA: {{ quote .Values.config.sdk.rfid.pkdPaPath }}
    {{- if .Values.config.sdk.rfid.paSensitiveCodes }}
    paSensitiveCodes: {{- toYaml .Values.config.sdk.rfid.paSensitiveCodes | nindent 4 }}
    {{- end }}
    chipVerification:
      enabled: {{ .Values.config.sdk.rfid.chipVerification.enabled }}
    {{- else }}
    {{- end }}

service:
  webServer:
    port: {{ .Values.config.service.webServer.port }}
    workers: {{ .Values.config.service.webServer.workers }}
    timeout: {{ .Values.config.service.webServer.timeout }}
    demoApp:
      enabled: {{ .Values.config.service.webServer.demoApp.enabled }}
    cors:
      origins: {{ quote .Values.config.service.webServer.cors.origins }}
      headers: {{ quote .Values.config.service.webServer.cors.headers }}
      methods: {{ quote .Values.config.service.webServer.cors.methods }}
    ssl:
      enabled: {{ .Values.config.service.webServer.ssl.enabled }}
      {{- if .Values.config.service.webServer.ssl.enabled }}
      cert: "certs/tls.crt"
      key: "certs/tls.key"
      tlsVersion: {{.Values.config.service.webServer.ssl.tlsVersion }}
      {{- else }}
      {{- end }}
    logging:
      level: {{ quote .Values.config.service.webServer.logging.level }}
      formatter: {{ quote .Values.config.service.webServer.logging.formatter }}
      access:
        console: {{ .Values.config.service.webServer.logging.access.console }}
        path: {{ quote .Values.config.service.webServer.logging.access.path }}
      app:
        console: {{ .Values.config.service.webServer.logging.app.console }}
        path: {{ quote .Values.config.service.webServer.logging.app.path }}
    metrics:
      enabled: {{ .Values.config.service.webServer.metrics.enabled }}

  storage:
    {{- if eq .Values.config.service.storage.type "fs" }}
    type: fs
    {{- end }}
    {{- if eq .Values.config.service.storage.type "s3" }}
    type: s3
    s3:
      {{- if .Values.config.service.storage.s3.awsCredentialsSecretName }}
      ## `storage.s3.accessKey/storage.s3.accessSecret` values have been overridden by `storage.s3.awsCredentialsSecretName` value
      {{- else }}
      accessKey: {{ .Values.config.service.storage.s3.accessKey }}
      accessSecret: {{ .Values.config.service.storage.s3.accessSecret }}
      {{- end }}
      region: {{ default "us-east-1" .Values.config.service.storage.s3.region | quote }}
      secure: {{ ne .Values.config.service.storage.s3.secure false }}
      endpointUrl: {{ default "https://s3.amazonaws.com" .Values.config.service.storage.s3.endpointUrl | quote }}
    {{- end }}
    {{- if eq .Values.config.service.storage.type "gcs" }}
    type: gcs
    gcs:
      gcsKeyJson: "/etc/credentials/gcs_key.json"
    {{- end }}
    {{- if eq .Values.config.service.storage.type "az" }}
    type: az
    {{- if .Values.config.service.storage.az.connectionStringSecretName }}
    ## `storage.az.connectionString` value has been overridden by `storage.az.connectionStringSecretName` value
    {{- else }}
    az:
      connectionString: {{ quote .Values.config.service.storage.az.connectionString }}
    {{- end }}
    {{- end }}
  {{- if or .Values.config.service.sessionApi.enabled .Values.config.sdk.rfid.chipVerification.enabled }}
  {{ if .Values.postgresql.enabled }}
  ## `database` configuration has been overridden by `postgresql.enabled=true` value
  database:
    connectionString: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ template "docreader.postgresql" . }}:5432/{{ .Values.postgresql.auth.database }}"
  {{- else }}
  {{- if .Values.config.service.database.connectionStringSecretName }}
  ## `database` configuration has been overridden by `database.connectionStringSecretName` value
  {{- else }}
  database:
    connectionString: {{ quote .Values.config.service.database.connectionString }}
  {{- end }}
  {{- end }}
  {{- end }}

  processing:
    enabled: {{ .Values.config.service.processing.enabled }}
    {{- if .Values.config.service.processing.enabled }}
    results:
      saveResult: {{ .Values.config.service.processing.results.saveResult }}
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.processing.results.location.bucket }}
        prefix: {{ quote .Values.config.service.processing.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.processing.results.location.container }}
        prefix: {{ quote .Values.config.service.processing.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.processing.results.location.folder }}
        {{- end }}
    {{- end }}

  sessionApi:
    enabled: {{ .Values.config.service.sessionApi.enabled }}
    {{- if .Values.config.service.sessionApi.enabled }}
    transactions:
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.sessionApi.transactions.location.bucket }}
        prefix: {{ quote .Values.config.service.sessionApi.transactions.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.sessionApi.transactions.location.container }}
        prefix: {{ quote .Values.config.service.sessionApi.transactions.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.sessionApi.transactions.location.folder }}
        {{- end }}
    {{- end }}
{{- end }}
