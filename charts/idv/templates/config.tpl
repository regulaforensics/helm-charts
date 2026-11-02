{{- define "idv.config" -}}
{{- include "idv.compat" . }}
mode: cluster
baseUrl: {{ quote .Values.config.baseUrl }}
fernetKey: {{ quote .Values.config.fernetKey }}
identifier: {{ quote .Values.config.identifier }}
tenant: {{ quote .Values.config.tenant }}
env: {{ quote .Values.config.env }}
basicAuth:
  enabled: {{ .Values.config.basicAuth.enabled }}

services:
  backoffice:
    enabled: true
    {{- if .Values.config.services.backoffice.baseUrl }}
    baseUrl: {{ quote .Values.config.services.backoffice.baseUrl }}
    {{- end }}
    port: {{ .Values.config.services.backoffice.port }}
    host: {{ quote .Values.config.services.backoffice.host }}
    workers: {{ .Values.config.services.backoffice.workers }}
    threads: {{ .Values.config.services.backoffice.threads }}
    keepalive: {{ .Values.config.services.backoffice.keepalive }}
    timeout: {{ .Values.config.services.backoffice.timeout }}
    cors:
      enabled: {{ .Values.config.services.backoffice.cors.enabled }}
      {{- if .Values.config.services.backoffice.cors.enabled }}
      origins: {{ quote .Values.config.services.backoffice.cors.origins }}
      methods: {{ quote .Values.config.services.backoffice.cors.methods }}
      headers: {{ quote .Values.config.services.backoffice.cors.headers }}
      maxAge: {{ .Values.config.services.backoffice.cors.maxAge }}
      {{- end }}
    maxBodySize: {{ .Values.config.services.backoffice.maxBodySize }}
    openapi: {{ .Values.config.services.backoffice.openapi }}

  frontoffice:
    enabled: {{ .Values.config.services.frontoffice.enabled }}
    {{- if .Values.config.services.frontoffice.baseUrl }}
    baseUrl: {{ quote .Values.config.services.frontoffice.baseUrl }}
    {{- end }}
    port: {{ .Values.config.services.frontoffice.port }}
    host: {{ quote .Values.config.services.frontoffice.host }}
    workers: {{ .Values.config.services.frontoffice.workers }}
    threads: {{ .Values.config.services.frontoffice.threads }}
    keepalive: {{ .Values.config.services.frontoffice.keepalive }}
    timeout: {{ .Values.config.services.frontoffice.timeout }}
    maxBodySize: {{ .Values.config.services.frontoffice.maxBodySize }}
    openapi: {{ .Values.config.services.frontoffice.openapi }}

  deviceGtw:
    enabled: {{ .Values.config.services.deviceGtw.enabled }}
    {{- if .Values.config.services.deviceGtw.baseUrl }}
    baseUrl: {{ quote .Values.config.services.deviceGtw.baseUrl }}
    {{- end }}
    port: {{ .Values.config.services.deviceGtw.port }}
    host: {{ quote .Values.config.services.deviceGtw.host }}
    workers: {{ .Values.config.services.deviceGtw.workers }}
    threads: {{ .Values.config.services.deviceGtw.threads }}
    keepalive: {{ .Values.config.services.deviceGtw.keepalive }}
    timeout: {{ .Values.config.services.deviceGtw.timeout }}
    maxBodySize: {{ .Values.config.services.deviceGtw.maxBodySize }}
    openapi: {{ .Values.config.services.deviceGtw.openapi }}

  workflow:
    enabled: true
    workers: {{ .Values.config.services.workflow.workers }}
    threads: {{ .Values.config.services.workflow.threads }}

  scheduler:
    enabled: true
    jobs:
      reloadWorkflows:
        cron: {{ quote .Values.config.services.scheduler.jobs.reloadWorkflows.cron }}
      expireSessions:
        cron: {{ quote .Values.config.services.scheduler.jobs.expireSessions.cron }}
      {{- if .Values.config.services.scheduler.jobs.cleanSessions }}
      cleanSessions:
        cron: {{ quote .Values.config.services.scheduler.jobs.cleanSessions.cron }}
        keepFor: {{ quote .Values.config.services.scheduler.jobs.cleanSessions.keepFor }}
      {{- end }}
      expireDeviceLogs:
        cron: {{ quote .Values.config.services.scheduler.jobs.expireDeviceLogs.cron }}
        keepFor: {{ quote .Values.config.services.scheduler.jobs.expireDeviceLogs.keepFor }}
      reloadLocales:
        cron: {{ quote .Values.config.services.scheduler.jobs.reloadLocales.cron }}
      cronWorkflow:
        cron: {{ quote .Values.config.services.scheduler.jobs.cronWorkflow.cron }}

  audit:
    enabled: true
    workers: {{ .Values.config.services.audit.workers }}
    threads: {{ .Values.config.services.audit.threads }}
    wsEnabled: {{ .Values.config.services.audit.wsEnabled }}
    user:
      keepFor: {{ quote .Values.config.services.audit.user.keepFor }}

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
    mode: {{ quote .Values.config.services.faceapi.mode }}
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
    {{- if .Values.config.services.livekit.apiKey }}
    apiKey: {{ quote .Values.config.services.livekit.apiKey }}
    {{- end }}
    {{- if .Values.config.services.livekit.apiSecret }}
    apiSecret: {{ quote .Values.config.services.livekit.apiSecret }}
    {{- end }}
    {{- if .Values.config.services.livekit.egress }}
    egress:
      enabled: {{ .Values.config.services.livekit.egress.enabled }}
    {{- end }}
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

topics:
  event:
    name: {{ if .Values.config.tenant }}{{ .Values.config.tenant }}-event{{ else }}event{{ end }}
    options:
      x-expires: 360000
  audit:
    name: {{ if .Values.config.tenant }}{{ .Values.config.tenant }}-audit{{ else }}audit{{ end }}
    options:
      x-expires: 360000
  config:
    name: {{ if .Values.config.tenant }}{{ .Values.config.tenant }}-config{{ else }}config{{ end }}
    options:
      x-expires: 360000
  client:
    name: {{ if .Values.config.tenant }}{{ .Values.config.tenant }}-client{{ else }}client{{ end }}
    options:
      durable: false
      x-expires: 60000
      x-message-ttl: 60000

storage:
  type: {{ .Values.config.storage.type }}
  {{- if eq .Values.config.storage.type "s3" }}
  {{- if .Values.minio.enabled }}
  ## `s3` configuration has been overridden by `minio.enabled=true` value
  s3:
    bucket: {{ quote (include "idv.storage.backendBucket" (dict "ctx" . "value" .Values.config.storage.s3.bucket)) }}
    endpoint: http://{{ template "idv.minio" . }}:9000
    accessKey: {{ quote (.Values.minio.auth.rootUser | default "console") }}
    accessSecret: {{ quote (.Values.minio.auth.rootPassword | default "console123") }}
    region: {{ quote .Values.config.storage.s3.region }}
    secure: false
  {{- else }}
  s3:
    bucket: {{ quote (include "idv.storage.backendBucket" (dict "ctx" . "value" .Values.config.storage.s3.bucket)) }}
    endpoint: {{ .Values.config.storage.s3.endpoint }}
    accessKey: {{ quote .Values.config.storage.s3.accessKey }}
    accessSecret: {{ quote .Values.config.storage.s3.accessSecret }}
    region: {{ quote .Values.config.storage.s3.region }}
    secure: {{ .Values.config.storage.s3.secure }}
  {{- end }}
  {{- end }}
  {{- if eq .Values.config.storage.type "az" }}
  az:
    container: {{ quote .Values.config.storage.az.container }}
    storageAccount: {{ quote .Values.config.storage.az.storageAccount }}
    connectionString: {{ quote .Values.config.storage.az.connectionString }}
  {{- end }}
  {{- if eq .Values.config.storage.type "gcs" }}
  gcs:
    bucket: {{ quote (include "idv.storage.backendBucket" (dict "ctx" . "value" .Values.config.storage.gcs.bucket)) }}
    {{- if .Values.config.storage.gcs.gcsKeyJsonSecretName }}
    gcsKeyJson: "/etc/credentials/gcs_key.json"
    {{- end }}
  {{- end }}

  sessions:
    location:
      prefix: {{ quote .Values.config.storage.sessions.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.sessions) }}{{ . | nindent 6 }}{{- end }}

  persons:
    location:
      prefix: {{ quote .Values.config.storage.persons.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.persons) }}{{ . | nindent 6 }}{{- end }}

  workflows:
    location:
      prefix: {{ quote .Values.config.storage.workflows.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.workflows) }}{{ . | nindent 6 }}{{- end }}

  userFiles:
    location:
      prefix: {{ quote .Values.config.storage.userFiles.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.userFiles) }}{{ . | nindent 6 }}{{- end }}

  locales:
    location:
      prefix: {{ quote .Values.config.storage.locales.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.locales) }}{{ . | nindent 6 }}{{- end }}

  assets:
    location:
      prefix: {{ quote .Values.config.storage.assets.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.assets) }}{{ . | nindent 6 }}{{- end }}

  tempFiles:
    location:
      prefix: {{ quote .Values.config.storage.tempFiles.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.tempFiles) }}{{ . | nindent 6 }}{{- end }}

  banlists:
    location:
      prefix: {{ quote .Values.config.storage.banlists.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.banlists) }}{{ . | nindent 6 }}{{- end }}

  thumbnails:
    location:
      prefix: {{ quote .Values.config.storage.thumbnails.location.prefix }}
      {{- with include "idv.storage.legacyLocation" (dict "entity" .Values.config.storage.thumbnails) }}{{ . | nindent 6 }}{{- end }}

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
    ## `textSearch` configuration has been overridden by `opensearch.enabled=true` value
    opensearch:
      host: opensearch
      port: "9200"
      useSsl: false
      verifyCerts: false
      username: ""
      password: ""
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

saml:
  enabled: {{ .Values.config.saml.enabled }}
  {{- if .Values.config.saml.enabled }}
  providers:
  {{- range .Values.config.saml.providers }}
    - name: {{ .name | quote }}
      defaultRoles: {{ .defaultRoles | toJson }}
      defaultGroups: {{ .defaultGroups | toJson }}
      entityId: {{ .entityId | quote }}
      ssoService:
        url: {{ .ssoService.url | quote }}
      security:
        x509cert: {{ .security.x509cert | quote }}
        {{- if .security.spPrivateKey }}
        spPrivateKey: {{ .security.spPrivateKey | quote }}
        {{- end }}
        {{- if .security.spPublicCert }}
        spPublicCert: {{ .security.spPublicCert | quote }}
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

rateLimit:
  enabled: {{ .Values.config.rateLimit.enabled }}
  {{- if .Values.config.rateLimit.enabled }}
  profiles:
  {{- range $profileName, $profileConfig := .Values.config.rateLimit.profiles }}
    {{ $profileName }}:
      window: {{ quote $profileConfig.window }}
      limit: {{ $profileConfig.limit }}
  {{- end }}
  {{- end }}

authorizedKeys:
  enabled: {{ .Values.config.authorizedKeys.enabled }}

sentry:
  portal:
    enabled: {{ .Values.config.sentry.portal.enabled }}
    {{- if .Values.config.sentry.portal.enabled }}
    {{- if .Values.config.sentry.portal.dsn }}
    dsn: {{ quote .Values.config.sentry.portal.dsn }}
    {{- end }}
    {{- if .Values.config.sentry.portal.environment }}
    environment: {{ quote .Values.config.sentry.portal.environment }}
    {{- end }}
    {{- end }}

{{- end }}
