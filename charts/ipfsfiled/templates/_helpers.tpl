{{/* "ipfsfiled.name" is "instanceName" truncated for use within k8s values */}}
{{- define "ipfsfiled.name" -}}
{{- (include "ipfsfiled.instanceName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* "ipfsfiled.instanceName" is generates a descriptive name of the instance based on release values or release.nameOverride */}}
{{- define "ipfsfiled.instanceName" -}}
{{- if and .Values.release .Values.release.nameOverride }}
{{- .Values.release.nameOverride }}
{{- else }}
{{- printf "%s-%s-%s"
      .Chart.Name
      (required "(root).release.environment expected" .Values.release.environment)
      .Release.Name
}}
{{- end }}
{{- end }}

{{/* "ipfsfiled.allLabels" generates a list of all labels to be used across statefulset resources */}}
{{- define "ipfsfiled.allLabels" -}}
{{ include "ipfsfiled.selectorLabels" . }}
{{ include "ipfsfiled.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* "ipfsfiled.releaseLabels" generates a list of common labels to be used across resources */}}
{{- define "ipfsfiled.releaseLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.ipfsfiled.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: sentinel
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}

{{/* "ipfsfiled.selectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "ipfsfiled.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ipfsfiled.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* "ipfsfiled.fingerprintAllArgs" accepts a set of args and returns a string fingerprint to uniquely identify that set. This is useful for automatically generating unique job names based on their input for later identification. */}}
{{/*
  Example:
    input: `--storage=db --confidence=100 --window=30s --tasks=blocks,messages,chaineconomics,actorstatesraw,actorstatespower,actorstatesreward,actorstatesmultisig,msapprovals`
    output: `s=db,c=100,w=30s,t=blmechSraSpoSreSmums,`
*/}}
{{- define "ipfsfiled.fingerprintAllArgs" -}}
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

{{/* "ipfsfiled.service-name-daemon-api" returns the full service name of the ipfsfiled daemon API endpoint. This is useful for DNS lookup of the API service. */}}
{{- define "ipfsfiled.service-name-daemon-api" -}}
  {{- printf "%s-%s" .Release.Name "ipfsfiled-daemon-api" }}
{{- end }}
