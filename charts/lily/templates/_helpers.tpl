{{/* "sentinel-lily.name" is "instanceName" truncated for use within k8s values */}}
{{- define "sentinel-lily.name" -}}
{{- (include "sentinel-lily.instanceName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* "sentinel-lily.instanceName" is generates a descriptive name of the instance based on release values or release.nameOverride */}}
{{- define "sentinel-lily.instanceName" -}}
{{- if and .Values.release .Values.release.nameOverride }}
{{- .Values.release.nameOverride }}
{{- else }}
{{- printf "%s-%s-%s-%s"
      .Chart.Name
      (required "(root).release.environment expected" .Values.release.environment)
      (required "(root).release.network expected" .Values.release.network)
      (required "(root).release.function expected" .Values.release.function)
}}
{{- end }}
{{- end }}

{{/* "sentinel-lily.labels" generates a list of common labels to be used across resources */}}
{{- define "sentinel-lily.labels" -}}
{{ include "sentinel-lily.selectorLabels" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: sentinel
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.selectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "sentinel-lily.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentinel-lily.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* "sentinel-lily.chainImportArgs" creates the arguments for managing optional chain import */}}
{{- define "sentinel-lily.chainImportArgs" }}
  if [ -f "/var/lib/lily/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/lily/datastore/_imported file."
    echo "Ensuring secrets have correct permissions."
    chmod 0600 /var/lib/lily/keystore/*
    exit 0
  fi
  echo "Importing snapshot from url {{ .Values.daemon.importSnapshot.url }}..."
  lily init --import-snapshot={{ .Values.daemon.importSnapshot.url }}
  status=$?
  if [ $status -eq 0 ]; then
    touch "/var/lib/lily/datastore/_imported"
  fi
  echo "Ensuring secrets have correct permissions."
  chmod 0600 /var/lib/lily/keystore/*
  exit $status
{{- end }}

{{- /* Helpers */}}
{{/* "sentinel-lily.jaegerTracingEnvvars" creates the envvars for supporting jaeger tracing */}}
{{- define "sentinel-lily.jaegerTracingEnvvars" -}}
{{- if and .Values.jaeger .Values.jaeger.enabled }}
- name: JAEGER_AGENT_HOST
{{- if .Values.jaeger.host }}
  value: {{ .Values.jaeger.host }}
{{- else }}
  valueFrom:
    fieldRef:
      apiVersion: v1
      fieldPath: status.hostIP
{{- end }}
- name: JAEGER_AGENT_PORT
  value: {{ .Values.jaeger.port | default "6831" | quote }}
- name: JAEGER_SERVICE_NAME
  value: {{ .Values.jaeger.serviceName | default (include "sentinel-lily.instanceName" . ) | quote }}
- name: JAEGER_SAMPLER_TYPE
  value: {{ .Values.jaeger.sampler.type | default "probabilistic" | quote }}
- name: JAEGER_SAMPLER_PARAM
  value: {{ .Values.jaeger.sampler.param | default "0.0001" | quote }}
{{- end }}
{{- end }}


{{/* "sentinel-lily.fingerprintAllArgs" accepts a set of args and returns a string fingerprint to uniquely identify that set. This is useful for automatically generating unique job names based on their input for later identification. */}}
{{/*
  Example:
    input: `--storage=db --confidence=100 --window=30s --tasks=blocks,messages,chaineconomics,actorstatesraw,actorstatespower,actorstatesreward,actorstatesmultisig,msapprovals`
    output: `s=db,c=100,w=30s,t=blmechSraSpoSreSmums,`
*/}}
{{- define "sentinel-lily.fingerprintAllArgs" -}}
{{- $fingerprint := "" }}
{{- range . }}
  {{- $t := lower (mustRegexReplaceAll "-+" . "") }}
  {{- /* Detect task list and handle fingerprinting specially */}}
  {{- if mustRegexMatch "^tasks=" $t }}
    {{- $taskList := trimPrefix "tasks=" $t }}
    {{- $taskFragment := "" }}
    {{- /* Split and range over tasklist split on `,` */}}
    {{- range (mustRegexSplit "," $taskList -1) }}
      {{- if mustRegexMatch "^actorstates" . }}
        {{- /* Detect `actorstates` tasks and prefix fragment w `S` to represent a task of this type in the fingerprint */}}
        {{- $taskFragment = printf "%sS%s" $taskFragment (trunc 2 (trimPrefix "actorstates" .)) }}
      {{- else }}
        {{- $taskFragment = printf "%s%s" $taskFragment (trunc 2 .) }}
      {{- end }}
    {{- end }}
    {{- $fingerprint = printf "%st=%s," $fingerprint $taskFragment }}
  {{- else }}
  {{- /* Otherwise, fingerprint w first letter of value before and value after */}}
    {{- $fragment := mustRegexReplaceAll "([a-z0-9])[a-z0-9]*(=?)([0-9]*[a-z]{0,2})" $t "${1}${2}${3}"  }}
    {{- $fingerprint = printf "%s%s," $fingerprint $fragment }}
  {{- end }}
{{- end }}
{{- $fingerprint }}
{{- end }}
