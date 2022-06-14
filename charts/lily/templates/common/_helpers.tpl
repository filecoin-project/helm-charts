{{/*
    value assertions and checks
/*}}

{{- if not or (eq .Values.deploymentType "cluster") (eq .Values.deploymentType "daemon") }}
{{- fail ".Values.deploymentType must be defined as `cluster` or `daemon`" }}
{{- end }}


{{/*
  truncated "instanceName" for use within k8s values
*/}}
{{- define "sentinel-lily.name" -}}
{{- (include "sentinel-lily.instanceName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
    generates a descriptive name of the instance based on release values or release.nameOverride
*/}}
{{- define "sentinel-lily.instanceName" -}}
{{- if and .Values.release .Values.release.nameOverride }}
{{- .Values.release.nameOverride }}
{{- else }}
{{- printf "%s-%s-%s-%s"
      .Chart.Name
      (required "(root).release.environment expected" .Values.release.environment)
      (required "(root).release.network expected" .Values.release.network)
      .Release.Name
}}
{{- end }}
{{- end }}

{{/* 
    generates a list of all labels to be used across statefulset resources
*/}}
{{- define "sentinel-lily.allLabels" -}}
{{ include "sentinel-lily.selectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
    generates a list of all labels to be used across statefulset resources
*/}}
{{- define "sentinel-lily.notifierAllLabels" -}}
{{ include "sentinel-lily.notifierSelectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
    generates a list of all labels to be used across statefulset resources
*/}}
{{- define "sentinel-lily.workerAllLabels" -}}
{{ include "sentinel-lily.workerSelectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/*
    generates a list of common labels to be used across resources
*/}}
{{- define "sentinel-lily.releaseLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: sentinel
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}

{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentinel-lily.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.notifierSelectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-%s" (include "sentinel-lily.name" .) "notifier" | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}-notifier
{{- end }}

{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.workerSelectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-%s" (include "sentinel-lily.name" .) "worker" | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}-worker
{{- end }}

{{/*
    creates the arguments for managing optional chain import
*/}}
{{- define "sentinel-lily.chainImportArgs" }}
{{- end }}

{{/*
    creates the envvars for supporting jaeger tracing
*/}}
{{- define "sentinel-lily.jaegerTracingEnvvars" -}}
{{- if and .Values.jaeger .Values.jaeger.enabled }}
- name: LILY_JAEGER_TRACING
  value: "true"
- name: LILY_JAEGER_SERVICE_NAME
  value: {{ .Values.jaeger.serviceName | default (include "sentinel-lily.instanceName" . ) | quote }}
- name: LILY_JAEGER_PROVIDER_URL
{{- include "sentinel-lily.jaegerProviderUrl" .Values.jaeger }}
- name: LILY_JAEGER_SAMPLER_RATIO
{{- if .Values.jaeger.sampler }}
  value: {{ .Values.jaeger.sampler.param | default 0.0001 | quote }}
{{- else }}
  value: {{ .Values.jaeger.samplerRatio | default "0.01" | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
    provides the providerUrl param or merges legacy host, port params
*/}}
{{- define "sentinel-lily.jaegerProviderUrl" -}}
{{- if .providerUrl }}
  value: {{ .providerUrl }}
{{- else -}}
  value: {{ printf "http://%s:%s/api/traces" .host .port }}
{{- end }}
{{- end }}

{{/*
    returns the full service name of the Lily daemon API endpoint.
    This is useful for DNS lookup of the API service.
*/}}
{{- define "sentinel-lily.service-name-daemon-api" -}}
  {{- printf "%s-%s" .Release.Name "lily-daemon-api" }}
{{- end }}

{{/*
    returns the full service name of the Lily daemon API endpoint.
    This is useful for DNS lookup of the API service.
*/}}
{{- define "sentinel-lily.service-name-redis-api" -}}
  {{- printf "%s-%s" .Release.Name "lily-redis-api" }}
{{- end }}

{{/*
    returns the name of a specific job defined within .Values.daemon.jobs
*/}}
{{- define "sentinel-lily.job-name-arg" -}}
{{ $jobName := "" -}}
{{- if .jobName -}}
  {{- $jobName = printf "--name %s/%s-`cat /var/lib/lily/uid`" .instanceName .jobName -}}
{{- else }}
  {{- $jobName = printf "--name \"%s-`cat /var/lib/lily/uid`/%s\"" .instanceName .command -}}
{{- end -}}
{{- $jobName -}}
{{- end -}}

{{/*
    resources" returns the minimal resource.requests for debug/init containers/
*/}}
{{- define "sentinel-lily.minimal-resources" }}
requests:
  cpu: "1000m"
  memory: "4Gi"
limits:
  cpu: "1000m"
  memory: "4Gi"
{{- end }}

{{/*
    create common nodeSelector, affinity, and tolerance values
*/}}
{{- define "sentinel-lily.common-lily-affinity-selectors" -}}
{{- with .Values.nodeSelector -}}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end -}}

{{/*
    common script for initializing the datastore for all deployments
*/}}
{{- define "sentinel-lily.initialize-datastore-script" -}}
- |
  set -x

  # generate 6-char random uid to be used in job report names
  if [ ! -f "/var/lib/lily/uid" ]; then
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w ${1:-6} | head -n 1 > /var/lib/lily/uid
  fi

  # create empty keystore
  if [ ! -f "/var/lib/lily/keystore" ]; then
    mkdir -p /var/lib/lily/keystore
  fi

  # import snapshot if enabled
  {{- if .Values.importSnapshot.enabled }}
  if [ -f "/var/lib/lily/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/lily/datastore/_imported file."
    echo "Ensuring secrets have correct permissions."
    chmod 0600 /var/lib/lily/keystore/*
    exit 0
  fi

  if [ ! -f "/var/lib/lily/datastore/snapshot.car" ]; then
    echo "*** Downloading snapshot from url {{ .Values.importSnapshot.url }}..."
    curl -sL -o ./aria2-1.36.0.deb https://github.com/q3aql/aria2-static-builds/releases/download/v1.36.0/aria2-1.36.0-linux-gnu-64bit-build1.deb
    dpkg -i ./aria2-1.36.0.deb
    rm ./aria2-1.36.0.deb

    (cd /var/lib/lily/datastore && aria2c -x16 -k1M -o snapshot.car {{ .Values.importSnapshot.url }})
    status=$?
    if [ $status -ne 0 ]; then
      rm /var/lib/lily/datastore/snapshot.car
      echo "...download failed: $status"
      exit $status
    fi
  fi


  echo "*** Importing snapshot..."
  lily init --import-snapshot=/var/lib/lily/datastore/snapshot.car
  status=$?
  if [ $status -eq 0 ]; then
    rm /var/lib/lily/datastore/snapshot.car
    touch "/var/lib/lily/datastore/_imported"
  fi

  echo "Ensuring secrets have correct permissions."
  chmod 0600 /var/lib/lily/keystore/*
  exit $status
  {{- end }}

{{- end -}}


{{/*
    return docker image string to pull
*/}}
{{- define "sentinel-lily.docker-image" }}
{{- required "(root).image.repo expected" .Values.image.repo }}:{{ default (printf "v%s" .Chart.AppVersion) .Values.image.tag }}
{{- end -}}

{{/*
    return lily environment variables
*/}}
{{- define "sentinel-lily.common-envvars" -}}
{{- include "sentinel-lily.jaegerTracingEnvvars" . | indent 8 }}
- name: GOLOG_LOG_FMT
  value: {{ .Values.logFormat | default "json" | quote }}
- name: GOLOG_LOG_LEVEL
  value: {{ .Values.logLevel | default "info" | quote }}
{{- if .Values.logLevelNamed }}
- name: LILY_LOG_LEVEL_NAMED
  value: {{ .Values.logLevelNamed | quote }}
{{- end }}
- name: LILY_REPO
  value: "/var/lib/lily"
- name: LILY_CONFIG
  value: "/var/lib/lily/config.toml"
{{- range .Values.daemon.storage.postgresql }}
- name: LILY_STORAGE_POSTGRESQL_{{ .name | upper }}_URL
  valueFrom:
    secretKeyRef:
      name: {{ required "expected secret name which holds postgres connection url" .secretName }}
      key: {{ .secretKey | default "url" }}
{{- end }}
{{- with .Values.daemon.env }}
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- end -}}
