{{/* "sentinel-archiver.name" is "instanceName" truncated for use within k8s values */}}
{{- define "sentinel-archiver.name" -}}
{{- (include "sentinel-archiver.instanceName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* "sentinel-archiver.instanceName" is generates a descriptive name of the instance based on release values or release.nameOverride */}}
{{- define "sentinel-archiver.instanceName" -}}
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

{{/* "sentinel-archiver.allLabels" generates a list of all labels to be used across statefulset resources */}}
{{- define "sentinel-archiver.allLabels" -}}
{{ include "sentinel-archiver.selectorLabels" . }}
{{ include "sentinel-archiver.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* "sentinel-archiver.releaseLabels" generates a list of common labels to be used across resources */}}
{{- define "sentinel-archiver.releaseLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.lily.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: sentinel
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}

{{/* "sentinel-archiver.selectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "sentinel-archiver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentinel-archiver.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* "sentinel-archiver.chainImportArgs" creates the arguments for managing optional chain import */}}
{{- define "sentinel-archiver.chainImportArgs" }}
  if [ -f "/var/lib/lily/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/lily/datastore/_imported file."
    echo "Ensuring secrets have correct permissions."
    chmod 0600 /var/lib/lily/keystore/*
    exit 0
  fi
  echo "Importing snapshot from url {{ .Values.network.snapshotUrl }}..."
  lily init --import-snapshot={{ .Values.network.snapshotUrl }}
  status=$?
  if [ $status -eq 0 ]; then
    touch "/var/lib/lily/datastore/_imported"
  fi
  echo "Ensuring secrets have correct permissions."
  chmod 0600 /var/lib/lily/keystore/*
  exit $status
{{- end }}

{{- /* Helpers */}}
{{/* "sentinel-archiver.jaegerTracingEnvvars" creates the envvars for supporting jaeger tracing */}}
{{- define "sentinel-archiver.jaegerTracingEnvvars" -}}
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
  value: {{ .Values.jaeger.serviceName | default (include "sentinel-archiver.instanceName" . ) | quote }}
- name: JAEGER_SAMPLER_TYPE
  value: {{ .Values.jaeger.sampler.type | default "probabilistic" | quote }}
- name: JAEGER_SAMPLER_PARAM
  value: {{ .Values.jaeger.sampler.param | default "0.0001" | quote }}
{{- end }}
{{- end }}


{{/* "sentinel-archiver.fingerprintAllArgs" accepts a set of args and returns a string fingerprint to uniquely identify that set. This is useful for automatically generating unique job names based on their input for later identification. */}}
{{/*
  Example:
    input: `--storage=db --confidence=100 --window=30s --tasks=blocks,messages,chaineconomics,actorstatesraw,actorstatespower,actorstatesreward,actorstatesmultisig,msapprovals`
    output: `s=db,c=100,w=30s,t=blmechSraSpoSreSmums,`
*/}}
{{- define "sentinel-archiver.fingerprintAllArgs" -}}
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

{{/* "sentinel-archiver.service-name-lily-api" returns the full service name of the Lily daemon API endpoint. This is useful for DNS lookup of the API service. */}}
{{- define "sentinel-archiver.service-name-lily-api" -}}
  {{- printf "%s-%s" .Release.Name "lily-api" }}
{{- end }}
