{{- define "idv.config" -}}
mode: cluster
baseUrl: {{ quote .Values.config.baseUrl }}
fernetKey: {{ quote .Values.config.fernetKey }}
identifier: {{ quote .Values.config.identifier }}
basicAuth:
  enabled: {{ .Values.config.basicAuth.enabled }}

services:
  api:
    enabled: true
    port: {{ .Values.config.services.api.port }}
    host: {{ quote .Values.config.services.api.host }}
    workers: {{ .Values.config.services.api.workers }}
    threads: {{ .Values.config.services.api.threads }}
    keepalive: {{ .Values.config.services.api.keepalive }}
    timeout: {{ .Values.config.services.api.timeout }}
    cors:
      enabled: {{ .Values.config.services.api.cors.enabled }}
      {{- if .Values.config.services.api.cors.enabled }}
      origins: {{ quote .Values.config.services.api.cors.origins }}
      methods: {{ quote .Values.config.services.api.cors.methods }}
      headers: {{ quote .Values.config.services.api.cors.headers }}
      maxAge: {{ .Values.config.services.api.cors.maxAge }}
      {{- end }}
    maxBodySize: {{ .Values.config.services.api.maxBodySize }}
    openapi: {{ .Values.config.services.api.openapi }}

  workflow:
    enabled: true
    workers: {{ .Values.config.services.workflow.workers }}

  scheduler:
    enabled: true
    jobs:
      reloadWorkflows:
        cron: {{ quote .Values.config.services.scheduler.jobs.reloadWorkflows.cron }}
      expireSessions:
        cron: {{ quote .Values.config.services.scheduler.jobs.expireSessions.cron }}
      cleanSessions:
        cron: {{ quote .Values.config.services.scheduler.jobs.cleanSessions.cron }}
        keepFor: {{ quote .Values.config.services.scheduler.jobs.cleanSessions.keepFor }}
      expireDeviceLogs:
        cron: {{ quote .Values.config.services.scheduler.jobs.expireDeviceLogs.cron }}
        keepFor: {{ quote .Values.config.services.scheduler.jobs.expireDeviceLogs.keepFor }}
      reloadLocales:
        cron: {{ quote .Values.config.services.scheduler.jobs.reloadLocales.cron }}
      cronWorkflow:
        cron: {{ quote .Values.config.services.scheduler.jobs.cronWorkflow.cron }}

  audit:
    enabled: true
    wsEnabled: {{ .Values.config.services.audit.wsEnabled }}

  indexer:
    enabled: true
    timeout: {{ .Values.config.services.indexer.timeout }}
    maxBatchSize: {{ .Values.config.services.indexer.maxBatchSize }}

  docreader:
    enabled: {{ .Values.config.services.docreader.enabled }}
    {{- if .Values.config.services.docreader.enabled }}
    prefix: {{ quote .Values.config.services.docreader.prefix }}
    url: {{ quote .Values.config.services.docreader.url }}
    {{- end }}

  faceapi:
    enabled: {{ .Values.config.services.faceapi.enabled }}
    {{- if .Values.config.services.faceapi.enabled }}
    prefix: {{ quote .Values.config.services.faceapi.prefix }}
    url: {{ quote .Values.config.services.faceapi.url }}
    {{- end }}
  
  ip2location:
    enabled: {{ .Values.config.services.ip2location.enabled }}
    {{- if .Values.config.services.ip2location.enabled }}
    type: {{ .Values.config.services.ip2location.type }}
    {{- if eq .Values.config.services.ip2location.type "regula" }}
    regula:
      url: {{ .Values.config.services.ip2location.regula.url }}
      timeout: {{ .Values.config.services.ip2location.regula.timeout }}
    {{- end }}
    {{- end }}
  
  livekit:
    enabled: {{ .Values.config.services.livekit.enabled }}
    {{- if .Values.config.services.livekit.enabled }}
    url: {{ quote .Values.config.services.livekit.url }}
    {{- end }}

mongo:
  {{- if .Values.mongodb.enabled }}
  ## `mongo` configuration has been overridden by `mongodb.enabled=true` value
  url: "mongodb://mongodb:27017/idv"
  {{- else }}
  url: {{ quote .Values.config.mongo.url }}
  {{- end }}

messageBroker:
  {{- if .Values.rabbitmq.enabled }}
  ## `messageBroker` configuration has been overridden by `rabbitmq.enabled=true` value
  url: "amqp://{{ .Values.rabbitmq.auth.username }}:{{ .Values.rabbitmq.auth.password }}@{{ template "idv.rabbitmq" . }}:5672/"
  {{- else }}
  url: {{ quote .Values.config.messageBroker.url }}
  {{- end }}

storage:
  {{- if eq .Values.config.storage.type "s3" }}
  type: s3
  {{- if .Values.minio.enabled }}
  ## `s3` configuration has been overridden by `minio.enabled=true` value
  s3:
    endpoint: http://{{ template "idv.minio" . }}:9000
    accessKey: console
    accessSecret: console123
    region: {{ quote .Values.config.storage.s3.region }}
    secure: false
  {{- else }}
  s3:
    endpoint: {{ .Values.config.storage.s3.endpoint }}
    accessKey: {{ quote .Values.config.storage.s3.accessKey }}
    accessSecret: {{ quote .Values.config.storage.s3.accessSecret }}
    region: {{ quote .Values.config.storage.s3.region }}
    secure: {{ .Values.config.storage.s3.secure }}
  {{- end }}
  {{- end }}

  sessions:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.sessions.location.bucket }}
      prefix: {{ quote .Values.config.storage.sessions.location.prefix }}
      {{- end }}

  persons:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.persons.location.bucket }}
      prefix: {{ quote .Values.config.storage.persons.location.prefix }}
      {{- end }}

  workflows:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.workflows.location.bucket }}
      prefix: {{ quote .Values.config.storage.workflows.location.prefix }}
      {{- end }}

  userFiles:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.userFiles.location.bucket }}
      prefix: {{ quote .Values.config.storage.userFiles.location.prefix }}
      {{- end }}

  locales:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.locales.location.bucket }}
      prefix: {{ quote .Values.config.storage.locales.location.prefix }}
      {{- end }}
  
  assets:
    location:
      {{- if eq .Values.config.storage.type "s3" }}
      bucket: {{ quote .Values.config.storage.assets.location.bucket }}
      prefix: {{ quote .Values.config.storage.assets.location.prefix }}
      {{- end }}

faceSearch:
  enabled: {{ .Values.config.faceSearch.enabled }}
  {{- if .Values.config.faceSearch.enabled }}
  limit: {{.Values.config.faceSearch.limit }}
  threshold: {{.Values.config.faceSearch.threshold }}
  database:
    type: {{ .Values.config.faceSearch.database.type }}
    {{- if eq .Values.config.faceSearch.database.type "opensearch" }}
    {{- if .Values.opensearch.enabled }}
    ## `faceSearch` configuration has been overridden by `opensearch.enabled=true` value
    opensearch:
      host: opensearch
      port: "9200"
      useSsl: false
      verifyCerts: false
      username: ""
      password: ""
      dimension: 512
      awsAuth:
        enabled: false
    {{- else }}
    opensearch:
      host: {{ quote .Values.config.faceSearch.database.opensearch.host }}
      port: {{ quote .Values.config.faceSearch.database.opensearch.port }}
      useSsl: {{ .Values.config.faceSearch.database.opensearch.useSsl }}
      verifyCerts: {{ .Values.config.faceSearch.database.opensearch.verifyCerts }}
      username: {{ quote .Values.config.faceSearch.database.opensearch.username }}
      password: {{ quote .Values.config.faceSearch.database.opensearch.password }}
      dimension: {{ .Values.config.faceSearch.database.opensearch.dimension }}
      method: {{ .Values.config.faceSearch.database.opensearch.method }}
      awsAuth:
        enabled: {{ .Values.config.faceSearch.database.opensearch.awsAuth.enabled }}
        region: {{ quote .Values.config.faceSearch.database.opensearch.awsAuth.region }}
        accessKey: {{ quote .Values.config.faceSearch.database.opensearch.awsAuth.accessKey }}
        secretKey: {{ quote .Values.config.faceSearch.database.opensearch.awsAuth.secretKey }}
    {{- end }}
    {{- end }}
    {{- if eq .Values.config.faceSearch.database.type "atlas" }}
    atlas: {{- toYaml .Values.config.faceSearch.database.atlas | nindent 6 }}
    {{- end }}
  {{- end }}

textSearch:
  enabled: {{ .Values.config.textSearch.enabled }}
  {{- if .Values.config.textSearch.enabled }}
  limit: {{.Values.config.textSearch.limit }}
  database:
    type: {{ .Values.config.textSearch.database.type }}
    {{- if eq .Values.config.textSearch.database.type "opensearch" }}
    {{- if .Values.opensearch.enabled }}
    ## `faceSearch` configuration has been overridden by `opensearch.enabled=true` value
    opensearch:
      host: opensearch
      port: "9200"
      useSsl: false
      verifyCerts: false
      username: ""
      password: ""
      dimension: 512
      awsAuth:
        enabled: false
    {{- else }}
    opensearch:
      host: {{ quote .Values.config.textSearch.database.opensearch.host }}
      port: {{ quote .Values.config.textSearch.database.opensearch.port }}
      useSsl: {{ .Values.config.textSearch.database.opensearch.useSsl }}
      verifyCerts: {{ .Values.config.textSearch.database.opensearch.verifyCerts }}
      username: {{ quote .Values.config.textSearch.database.opensearch.username }}
      password: {{ quote .Values.config.textSearch.database.opensearch.password }}
      awsAuth:
        enabled: {{ .Values.config.textSearch.database.opensearch.awsAuth.enabled }}
        region: {{ quote .Values.config.textSearch.database.opensearch.awsAuth.region }}
        accessKey: {{ quote .Values.config.textSearch.database.opensearch.awsAuth.accessKey }}
        secretKey: {{ quote .Values.config.textSearch.database.opensearch.awsAuth.secretKey }}
    {{- end }}
    {{- end }}
    {{- if eq .Values.config.textSearch.database.type "atlas" }}
    atlas: {{- toYaml .Values.config.textSearch.database.atlas | nindent 6 }}
    {{- end }}
  {{- end }}

mobile:
{{ .Values.config.mobile | toYaml | indent 2 }}

smtp:
  enabled: {{ .Values.config.smtp.enabled }}
  {{- if .Values.config.smtp.enabled }}
  host: {{ .Values.config.smtp.host | quote }}
  port: {{ .Values.config.smtp.port }}
  username: {{ .Values.config.smtp.username | quote }}
  password: {{ .Values.config.smtp.password | quote }}
  tls: {{ .Values.config.smtp.tls }}
  {{- end }}

oauth2:
  enabled: {{ .Values.config.oauth2.enabled }}
  {{- if .Values.config.oauth2.enabled }}
  accessTokenTtl: {{ .Values.config.oauth2.accessTokenTtl }}
  refreshTokenTtl: {{ .Values.config.oauth2.refreshTokenTtl }}
  providers:
  {{- range .Values.config.oauth2.providers }}
    - name: {{ .name | quote }}
      clientId: {{ .clientId | quote }}
      scope: {{ .scope | quote }}
      secret: {{ .secret | quote }}
      type: {{ .type | quote }}
      defaultRoles: {{ .defaultRoles | toJson }}
      defaultGroups: {{ .defaultGroups | toJson }}
      urls:
        jwk: {{ .urls.jwk | quote }}
        authorize: {{ .urls.authorize | quote }}
        token: {{ .urls.token | quote }}
        {{- if .urls.refresh }}
        refresh: {{ .urls.refresh | quote }}
        {{- end }}
        {{- if .urls.revoke }}
        revoke: {{ .urls.revoke | quote }}
        {{- end }}
  {{- end }}
  {{- end }}

logging:
  level: {{ quote .Values.config.logging.level }}
  formatter: {{ quote .Values.config.logging.formatter }}
  console: {{ .Values.config.logging.console }}
  file: {{ .Values.config.logging.file }}
  path: {{ quote .Values.config.logging.path }}
  maxFileSize: {{ .Values.config.logging.maxFileSize }}
  filesCount: {{ .Values.config.logging.filesCount }}

metrics:
  statsd:
    enabled: {{ .Values.config.metrics.statsd.enabled }}
    {{- if .Values.config.metrics.statsd.enabled }}
    {{- if .Values.statsd.enabled }}
    ## prometheus-statsd-exporter subchart is enabled
    host: {{ template "idv.statsd" . }}
    port: {{ .Values.statsd.statsd.tcpPort | default 9125 }}
    {{- else }}
    host: {{ quote .Values.config.metrics.statsd.host }}
    port: {{ .Values.config.metrics.statsd.port | default 9125 }}
    {{- end }}
    prefix: {{ quote .Values.config.metrics.statsd.prefix }}
    {{- end }}

deviceRegistration:
  enabled: {{ .Values.config.deviceRegistration.enabled }}

{{- end }}
