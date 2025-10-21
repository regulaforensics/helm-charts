{{- define "faceapi.config" -}}
sdk:
  compare:
    limitPerImageTypes: {{ .Values.config.sdk.compare.limitPerImageTypes }}

  {{- if .Values.config.sdk.param }}
  param: {{- toYaml .Values.config.sdk.param | nindent 4 }}
  {{- end }}

  {{- if .Values.config.sdk.detect }}
  detect: {{- toYaml .Values.config.sdk.detect | nindent 4 }}
  {{- end }}

  {{- if and .Values.config.service.liveness.enabled .Values.config.sdk.liveness }}
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
      {{- end }}
    logging:
      level: {{ quote .Values.config.service.webServer.logging.level }}
      formatter: {{ quote .Values.config.service.webServer.logging.formatter }}
      access:
        console: {{ .Values.config.service.webServer.logging.access.console }}
        path: {{ quote .Values.config.service.webServer.logging.access.path }}
        format: {{ quote .Values.config.service.webServer.logging.access.format }}
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
    {{- if and (hasKey .Values.config.service.storage "gcs") .Values.config.service.storage.gcs.gcsKeyJsonSecretName }}
    gcs:
      gcsKeyJson: "/etc/credentials/gcs_key.json"
    {{- end }}
    {{- end }}
    {{- if eq .Values.config.service.storage.type "az" }}
    type: az
    {{- if .Values.config.service.storage.az.connectionStringSecretName }}
    ## `config.service.storage.az.connectionString` value has been overridden by `config.service.storage.az.connectionStringSecretName` value
    {{- else }}
    az:
      storageAccount: {{ quote .Values.config.service.storage.az.storageAccount }}
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
    {{- if .Values.config.service.database.passwordlessAuth.enabled }}
    passwordlessAuth:
      enabled: true
      {{- if eq .Values.config.service.database.passwordlessAuth.type "az" }}
      type: "az"
      az:
        scope: {{ quote .Values.config.service.database.passwordlessAuth.az.scope }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}

  detectMatch:
    enabled: {{ .Values.config.service.detectMatch.enabled }}
    {{- if .Values.config.service.detectMatch.enabled }}
    {{- with .Values.config.service.detectMatch.selfOrigins }}
    selfOrigins: {{- toYaml . | nindent 6 }}
    {{- end }}
    results:
      audit: {{ .Values.config.service.detectMatch.results.audit }}
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
    {{- end }}

  liveness:
    enabled: {{ .Values.config.service.liveness.enabled }}
    {{- if .Values.config.service.liveness.enabled }}
    ecdhSchema: {{ quote .Values.config.service.liveness.ecdhSchema }}
    hideMetadata: {{ .Values.config.service.liveness.hideMetadata }}
    consistency: {{ quote .Values.config.service.liveness.consistency }}
    {{- if .Values.config.service.liveness.exposeData }}
    exposeData: {{- toYaml .Values.config.service.liveness.exposeData | nindent 6 }}
    {{- end }}
    {{- if .Values.config.service.liveness.config }}
    config: {{- toYaml .Values.config.service.liveness.config | nindent 6 }}
    {{- end }}
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
    {{- if .Values.config.service.search.results }}
    results:
      audit: {{ .Values.config.service.search.results.audit }}
      location:
        {{- if or (eq .Values.config.service.storage.type "s3") (eq .Values.config.service.storage.type "gcs") }}
        bucket: {{ quote .Values.config.service.search.results.location.bucket }}
        prefix: {{ quote .Values.config.service.search.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "az" }}
        container: {{ quote .Values.config.service.search.results.location.container }}
        prefix: {{ quote .Values.config.service.search.results.location.prefix }}
        {{- end }}
        {{- if eq .Values.config.service.storage.type "fs" }}
        folder: {{ quote .Values.config.service.search.results.location.folder }}
        {{- end }}
    {{- end }}

    threshold: {{ .Values.config.service.search.threshold }}

    {{ $vd := .Values.config.service.search.vectorDatabase | default dict -}}
    {{- $type := $vd.type | default "" -}}
    vectorDatabase:
      type: {{ $type }}
      {{ if eq $type "milvus" }}
      {{- $mil := $vd.milvus | default dict -}}
      milvus:
        user: {{ default "" $mil.user | quote }}
        password: {{ default "" $mil.password | quote }}
        token: {{ default "" $mil.token | quote }}
        {{- if .Values.milvus.enabled }}
        ## overridden by milvus.enabled=true
        endpoint: "http://{{ template "faceapi.milvus" . }}"
        {{- else }}
        endpoint: {{ default "http://milvus:19530" $mil.endpoint | quote }}
        {{- end }}
        consistency: {{ default "Bounded" $mil.consistency | quote }}
        reload: {{ default false $mil.reload }}
        index:
          {{ $ix := (default dict $mil.index) -}}
          type: {{ default "IVF_FLAT" $ix.type | quote }}
          params:
            {{ $ixp := (default dict $ix.params) -}}
            nlist: {{ default 128 $ixp.nlist }}
        search:
          {{ $srch := (default dict $mil.search) -}}
          type: {{ default "L2" $srch.type | quote }}
          params:
            {{ $sp := (default dict $srch.params) -}}
            nprobe: {{ default 5 $sp.nprobe }}
      {{- end }}
      {{- if eq $type "opensearch" }}
      {{- $os := $vd.opensearch | default dict -}}
      opensearch:
        host: {{ default "opensearch" $os.host | quote }}
        port: {{ default 9200 $os.port }}
        useSsl: {{ default false $os.useSsl }}
        verifyCerts: {{ default false $os.verifyCerts }}
        username: {{ default "admin" $os.username | quote }}
        password: {{ default "admin" $os.password | quote }}
        dimension: {{ default 512 $os.dimension }}
        awsAuth:
          {{ $aws := $os.awsAuth | default dict -}}
          enabled: {{ default false $aws.enabled }}
          {{- if (default false $aws.enabled) }}
          region: {{ default nil $aws.region }}
          accessKey: {{ default nil $aws.accessKey }}
          secretKey: {{ default nil $aws.secretKey }}
          {{- end }}
      {{- end }}
      {{- if eq $type "atlas" }}
      {{- $at := $vd.atlas | default dict -}}
      atlas:
        connectionString: {{ default "" $at.connectionString | quote }}
      {{- end }}
    {{- end }}

  houseKeeper:
    enabled: {{ .Values.config.service.houseKeeper.enabled }}
    {{- if .Values.config.service.houseKeeper.enabled }}
    beatCadence: {{ .Values.config.service.houseKeeper.beatCadence }}
    keepFor: {{ .Values.config.service.houseKeeper.keepFor }}
    liveness:
      enabled: {{ .Values.config.service.houseKeeper.liveness.enabled }}
      keepFor: {{ .Values.config.service.houseKeeper.liveness.keepFor | int64 }}
    search:
      enabled: {{ .Values.config.service.houseKeeper.search.enabled }}
      keepFor: {{ .Values.config.service.houseKeeper.search.keepFor | int64 }}
    {{- end }}
{{- end }}
