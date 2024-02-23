{{- define "faceapi.config" -}}
sdk:
  compare:
    limitPerImageTypes: {{ .Values.config.sdk.compare.limitPerImageTypes }}
  logging:
    level: {{ quote .Values.config.sdk.logging.level }}

  {{- if .Values.config.sdk.detect }}
  detect: {{- toYaml .Values.config.sdk.detect | nindent 4 }}
  {{- end }}

  {{- if and .Values.config.service.liveness.enabled .Values.config.sdk.liveness  }}
  liveness: {{- toYaml .Values.config.sdk.liveness | nindent 4 }}
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
      tlsVersion: {{ .Values.config.service.webServer.ssl.tlsVersion }}
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
      ## `config.service.storage.s3.accessKey/config.service.storage.s3.accessSecret` values have been overridden by `config.service.storage.s3.awsCredentialsSecretName` value
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
    ## `config.service.storage.az.connectionString` value has been overridden by `config.service.storage.az.connectionStringSecretName` value
    {{- else }}
    az:
      connectionString: {{ quote .Values.config.service.storage.az.connectionString }}
    {{- end }}
    {{- end }}
  {{- if or .Values.config.service.liveness.enabled .Values.config.service.search.enabled }}
  {{ if .Values.postgresql.enabled }}
  ## `database` configuration has been overridden by `postgresql.enabled=true` value
  database:
    connectionString: "postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ template "faceapi.postgresql" . }}:5432/{{ .Values.postgresql.auth.database }}"
  {{- else }}
  {{- if .Values.config.service.database.connectionStringSecretName }}
  ## `database` configuration has been overridden by `database.connectionStringSecretName` value
  {{- else }}
  database:
    connectionString: {{ quote .Values.config.service.database.connectionString }}
  {{- end }}
  {{- end }}
  {{- end }}

  detectMatch:
    enabled: {{ .Values.config.service.detectMatch.enabled }}
    {{- if .Values.config.service.detectMatch.enabled }}
    results:
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.detectMatch.results.location.bucket }}
        prefix: {{ quote .Values.config.service.detectMatch.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.detectMatch.results.location.container }}
        prefix: {{ quote .Values.config.service.detectMatch.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.detectMatch.results.location.folder }}
        {{- end }}
    {{- else }}
    {{- end }}

  liveness:
    enabled: {{ .Values.config.service.liveness.enabled }}
    {{- if .Values.config.service.liveness.enabled }}
    ecdhSchema: {{ quote .Values.config.service.liveness.ecdhSchema }}
    hideMetadata: {{ .Values.config.service.liveness.hideMetadata }}
    protectPersonalInfo: {{ .Values.config.service.liveness.protectPersonalInfo }}
    sessions:
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.liveness.sessions.location.bucket }}
        prefix: {{ quote .Values.config.service.liveness.sessions.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.liveness.sessions.location.container }}
        prefix: {{ quote .Values.config.service.liveness.sessions.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.liveness.sessions.location.folder }}
        {{- end }}
    {{- else }}
    {{- end }}

  search:
    enabled: {{ .Values.config.service.search.enabled }}
    {{- if .Values.config.service.search.enabled }}
    persons:
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.search.persons.location.bucket }}
        prefix: {{ quote .Values.config.service.search.persons.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.search.persons.location.container }}
        prefix: {{ quote .Values.config.service.search.persons.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.search.persons.location.folder }}
        {{- end }}

    threshold: {{ .Values.config.service.search.threshold }}

    vectorDatabase:
      type: {{ quote .Values.config.service.search.vectorDatabase.type }}
      {{- if eq .Values.config.service.search.vectorDatabase.type "milvus" }}
      milvus:
        user: {{ quote .Values.config.service.search.vectorDatabase.milvus.user }}
        password: {{ quote .Values.config.service.search.vectorDatabase.milvus.password }}
        token: {{ quote .Values.config.service.search.vectorDatabase.milvus.token }}
        {{- if .Values.milvus.enabled }}
        ## `config.service.search.vectorDatabase.milvus.endpoint` value has been overridden by `milvus.enabled=true` value
        endpoint: "http://{{ template "faceapi.milvus" . }}"
        {{- else }}
        endpoint: {{ quote .Values.config.service.search.vectorDatabase.milvus.endpoint }}
        {{- end }}
        consistency: {{ quote .Values.config.service.search.vectorDatabase.milvus.consistency }}
        reload: {{ .Values.config.service.search.vectorDatabase.milvus.reload }}
        index:
          type: {{ quote .Values.config.service.search.vectorDatabase.milvus.index.type }}
          params:
            nlist: {{ .Values.config.service.search.vectorDatabase.milvus.index.params.nlist }}
        search:
          type: {{ quote .Values.config.service.search.vectorDatabase.milvus.search.type }}
          params:
            nprobe: {{ .Values.config.service.search.vectorDatabase.milvus.search.params.nprobe }}
      {{- else }}
      {{- end }}
    {{- else }}
    {{- end }}
{{- end }}
