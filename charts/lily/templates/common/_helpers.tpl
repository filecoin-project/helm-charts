{{/*
    value assertions and checks
/*}}

{{- if not or (eq .Values.deploymentType "cluster") (eq .Values.deploymentType "daemon") }}
{{- fail ".Values.deploymentType must be defined as `cluster` or `daemon`" }}
{{- end }}



{{/*
    generates a descriptive name of the instance based on release values or release.nameOverride
*/}}
{{- define "sentinel-lily.instance-name" -}}
{{- if and .Values.release .Values.release.nameOverride }}
{{- .Values.release.nameOverride | lower }}
{{- else }}
{{- printf "%s-%s-%s-%s"
      .Chart.Name
      .Release.Name
      (required "(root).release.environment expected" .Values.release.environment)
      (required "(root).release.network expected" .Values.release.network)
 | lower }}
{{- end }}
{{- end }}


{{/*
  truncated "instance-name" for use within k8s values
*/}}
{{- define "sentinel-lily.short-instance-name" -}}
{{- (include "sentinel-lily.instance-name" . ) | trunc 32 | trimSuffix "-" }}
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
helm.sh/chart: {{ list .Chart.Name .Chart.Version | join "-" | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: "sentinel"
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}


{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name | lower | quote }}
app.kubernetes.io/instance: {{ include "sentinel-lily.instance-name" . | quote }}
{{- end }}


{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.notifierSelectorLabels" -}}
app.kubernetes.io/name: {{ list .Chart.Name "notifier" | join "-" | lower | quote }}
app.kubernetes.io/instance: {{ list ( include "sentinel-lily.short-instance-name" . ) "notifier" | join "-" | quote }}
{{- end }}


{{/*
    generates a list of selector labels to be used across resources
*/}}
{{- define "sentinel-lily.workerSelectorLabels" -}}
app.kubernetes.io/name: {{ list .Chart.Name "worker" | join "-" | lower | quote }}
app.kubernetes.io/instance: {{ list ( include "sentinel-lily.short-instance-name" . ) "worker" | join "-" | quote }}
{{- end }}


{{/*
    creates the envvars for supporting jaeger tracing
*/}}
{{- define "sentinel-lily.jaegerTracingEnvvars" -}}
{{- if and .Values.jaeger .Values.jaeger.enabled }}
- name: LILY_JAEGER_TRACING
  value: "true"
- name: LILY_JAEGER_SERVICE_NAME
  value: {{ .Values.jaeger.serviceName | default (include "sentinel-lily.instance-name" . ) | quote }}
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
    builds the template specific for each app type
*/}}
{{- define "sentinel-lily.daemon-api-service-template" -}}
{{- include "sentinel-lily.app-api-service-template" (list "daemon" .) }}
{{- end -}}

{{- define "sentinel-lily.notifier-api-service-template" -}}
{{- include "sentinel-lily.app-api-service-template" (list "notifier" .) }}
{{- end -}}

{{- define "sentinel-lily.worker-api-service-template" -}}
{{- include "sentinel-lily.app-api-service-template" (list "worker" .) }}
{{- end -}}

{{- define "sentinel-lily.app-api-service-template" -}}
{{- $instanceType := index . 0 -}}
{{- $root := index . 1 -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ list ( include "sentinel-lily.short-instance-name" $root ) $instanceType "api-svc" | join "-" | quote }}
  labels:
    {{- include "sentinel-lily.allLabels" $root | nindent 4 }}
spec:
  type: ClusterIP
  selector:
    {{- include "sentinel-lily.selectorLabels" $root | nindent 4 }}
  ports:
  - name: "api-port"
    protocol: "TCP"
    port: 1234
{{- end -}}


{{/*
    returns the minimal resource.requests for debug/init containers/
*/}}
{{- define "sentinel-lily.minimal-resources" }}
requests:
{{- if .requests }}
  cpu: {{ .requests.cpu | default "1000m" }}
  memory: {{ .requests.memory | default "4Gi" }}
{{- else }}
  cpu: "1000m"
  memory: "4Gi"
{{- end }}
limits:
{{- if .limits }}
  cpu: {{ .limits.cpu | default "1000m" }}
  memory: {{ .limits.memory | default "4Gi" }}
{{- else }}
  cpu: "1000m"
  memory: "4Gi"
{{- end }}
{{- end }}


{{/*
    returns a default of resource for lily daemon containers to run all tasks
*/}}
{{- define "sentinel-lily.app-resources" }}
requests:
{{- if .requests }}
  cpu: {{ .requests.cpu | default "16000m" }}
  memory: {{ .requests.memory | default "225Gi" }}
{{- else }}
  cpu: "16000m"
  memory: "225Gi"
{{- end }}
limits:
{{- if .limits }}
  cpu: {{ .limits.cpu | default "16000m" }}
  memory: {{ .limits.memory | default "225Gi" }}
{{- else }}
  cpu: "16000m"
  memory: "225Gi"
{{- end }}
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
    chmod -R 0600 /var/lib/lily/keystore
  fi

  # import snapshot if enabled
  {{- if .Values.importSnapshot.enabled }}
  if [ -f "/var/lib/lily/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/lily/datastore/_imported file."
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
      if [ -f /var/lib/lily/datastore/snapshot.car ]; then
        rm /var/lib/lily/datastore/snapshot.car
      fi
      echo "...download failed: $status"
      exit $status
    fi
  fi

  echo "*** Importing snapshot..."
  lily init --import-snapshot=/var/lib/lily/datastore/snapshot.car
  status=$?
  if [ $status -eq 0 ]; then
    touch "/var/lib/lily/datastore/_imported"
  fi
  # always remove so we can do a fresh download on next start
  rm /var/lib/lily/datastore/snapshot.car

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
- name: LILY_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-redis
      key: "redis-password"
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


{{/*
    common volume mount values for all deployment types
*/}}
{{- define "sentinel-lily.common-volume-mounts" }}
- name: "repo-volume"
  mountPath: "/var/lib/lily"
- name: "config-volume"
  mountPath: "/var/lib/lily/config.toml"
  subPath: "config.toml"
  readOnly: true
{{- if .Values.daemon.volumes.datastore.enabled }}
- name: "datastore-volume"
  mountPath: "/var/lib/lily/datastore"
{{- end }}
{{- end -}}


{{/*
    returns the name of a specific job defined within .Values.daemon.jobs
*/}}
{{- define "sentinel-lily.job-name-arg" -}}
{{- $instanceName := index . 0 -}}
{{- $jobName := index . 1 -}}
{{- printf "--name=%s" (printf "%s/%s-`cat /var/lib/lily/uid`" $instanceName $jobName | quote ) -}}
{{- end -}}


{{/*
    common script to start jobs on starting daemon
*/}}
{{- define "sentinel-lily.common-job-start-script" }}
{{- $values := index . 0 -}}
{{- $instanceType := index . 1 -}}
# lifecycle.postStart.exec.command doesn't accept args
# so we execute this script as a multiline string
- "/bin/sh"
- "-c"
- |
  echo "Waiting for api to become ready..."
  lily wait-api --timeout={{ $values.apiWaitTimeout | quote }} > /dev/null 2>&1
  status=$?
  if [ $status -ne 0 ]; then
    echo "exit with code $status"
    exit $status
  fi

  # wait 3 minutes to let the node's datastore settle
  echo "Waiting for datastore to settle... (3m)"
  sleep 180

  {{- if eq $instanceType "daemon" }}
    {{- $jobs := $values.daemon.jobs -}}
    {{- if $jobs }}
    echo "Starting jobs..."
    {{- range $jobs }}
    echo "...starting job '{{ .name | default .command }}'"
  lily sync wait && sleep 10 && lily job run {{ .jobArgs | join " " }} {{ include "sentinel-lily.job-name-arg" (list $values.instanceName ( .name | default .command )) }} {{ .command }} {{ .commandArgs | join " " }}
  status=$?
  if [ $status -ne 0 ]; then
    echo "exit with code $status"
    exit $status
  fi
    {{- end }}
    {{- end }}


  {{- else if eq $instanceType "notifier" }}
    {{- $jobs := $values.cluster.jobs -}}
    {{- if $jobs }}
  echo "Starting jobs..."
    {{- range $jobs }}
    echo "...starting job '{{ .name | default .command }}'"
  lily sync wait && sleep 10 && lily job run {{ .jobArgs | join " " }} --restart-on-failure --storage={{ .storage | quote }} {{ include "sentinel-lily.job-name-arg" (list .Values.instanceName ( .name | default .command )) }} {{ .jobArgs | join " " }} {{ .command }} {{ .commandArgs | join " " }} notify --queue={{ .queue | quote }}
  status=$?
  if [ $status -ne 0 ]; then
    echo "exit with code $status"
    exit $status
  fi
    {{- end }}
    {{- end }}


  {{- else if eq $instanceType "worker" }}
    {{- $jobs := $values.daemon.jobs -}}
    {{- if $jobs }}
  echo "Starting jobs..."
    {{- range $jobs }}
    echo "...starting job '{{ .name | default .command }}'"
  lily sync wait && sleep 10 && lily job run {{ .jobArgs | join " " }} --restart-on-failure --storage={{ .storage | quote }} {{ include "sentinel-lily.job-name-arg" (list .Values.instanceName ( .name | default .command )) }} {{ .jobArgs | join " " }} tipset-worker --queue={{ .queue | quote }}
  status=$?
  if [ $status -ne 0 ]; then
    echo "exit with code $status"
    exit $status
  fi
    {{- end }}
    {{- end }}
  {{- else }}
  {{- fail printf "Unexpected $instanceType: %s" $instanceType }}
  {{- end }}
{{- end -}}


{{/*
    common volume claim templates for PVCs
*/}}
{{- define "sentinel-lily.volume-claim-templates" }}
{{- if .enabled }}
- apiVersion: v1
  kind: "PersistentVolumeClaim"
  metadata:
    name: "datastore-volume"
  spec:
    accessModes:
    {{- range .accessModes }}
    - {{ . | quote }}
    {{- end }}
    storageClassName: {{ .storageClassName }}
    volumeMode: "Filesystem"
    resources:
      requests:
        storage: {{ .size | quote }}
    {{- with .dataSource }}
    dataSource:
      {{- toYaml . | nindent 10 }}
    {{- end }}
{{- end }}
{{- end -}}


{{/*
    common volume mount configuration
*/}}
{{- define "sentinel-lily.volume-mounts" }}
- name: "repo-volume"
  emptyDir: {}
- name: "config-volume"
  configMap:
    name: {{ list .Release.Name "lily-config" | join "-" | quote }}
    items:
    - key: "config.toml"
      path: "config.toml"
{{- end -}}
