{{/* value assertions /*}}

{{- if not or (eq .Values.deploymentType "cluster") (eq .Values.deploymentType "daemon") }}
{{- fail ".Values.deploymentType must be defined as `cluster` or `daemon`" }}
{{- end }}


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
      .Release.Name
}}
{{- end }}
{{- end }}

{{/* "sentinel-lily.allLabels" generates a list of all labels to be used across statefulset resources */}}
{{- define "sentinel-lily.allLabels" -}}
{{ include "sentinel-lily.selectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.notifierAllLabels" generates a list of all labels to be used across statefulset resources */}}
{{- define "sentinel-lily.notifierAllLabels" -}}
{{ include "sentinel-lily.notifierSelectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.workerAllLabels" generates a list of all labels to be used across statefulset resources */}}
{{- define "sentinel-lily.workerAllLabels" -}}
{{ include "sentinel-lily.workerSelectorLabels" . }}
{{ include "sentinel-lily.releaseLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.releaseLabels" generates a list of common labels to be used across resources */}}
{{- define "sentinel-lily.releaseLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: sentinel
{{- if .Values.release }}
{{ toYaml .Values.release }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.selectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "sentinel-lily.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentinel-lily.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* "sentinel-lily.notifierSelectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "sentinel-lily.notifierSelectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-%s" (include "sentinel-lily.name" .) "notifier" | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}-notifier
{{- end }}

{{/* "sentinel-lily.workerSelectorLabels" generates a list of selector labels to be used across resources */}}
{{- define "sentinel-lily.workerSelectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-%s" (include "sentinel-lily.name" .) "worker" | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}-worker
{{- end }}

{{/* "sentinel-lily.chainImportArgs" creates the arguments for managing optional chain import */}}
{{- define "sentinel-lily.chainImportArgs" }}
{{- end }}

{{- /* Helpers */}}
{{/* "sentinel-lily.jaegerTracingEnvvars" creates the envvars for supporting jaeger tracing */}}
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

{{/* "sentinel-lily.jaegerProviderUrl" provides the providerUrl param or merges legacy host, port params */}}
{{- define "sentinel-lily.jaegerProviderUrl" -}}
{{- if .providerUrl }}
  value: {{ .providerUrl }}
{{- else -}}
  value: {{ printf "http://%s:%s/api/traces" .host .port }}
{{- end }}
{{- end }}

{{/* "sentinel-lily.service-name-daemon-api" returns the full service name of the Lily daemon API endpoint. This is useful for DNS lookup of the API service. */}}
{{- define "sentinel-lily.service-name-daemon-api" -}}
  {{- printf "%s-%s" .Release.Name "lily-daemon-api" }}
{{- end }}

{{/* "sentinel-lily.service-name-redis-api" returns the full service name of the Lily daemon API endpoint. This is useful for DNS lookup of the API service. */}}
{{- define "sentinel-lily.service-name-redis-api" -}}
  {{- printf "%s-%s" .Release.Name "lily-redis-api" }}
{{- end }}

{{/* "sentinel-lily.job-name" returns the name of a specific job defined within .Values.daemon.jobs */}}
{{- define "sentinel-lily.job-name-arg" -}}
{{ $jobName := "" -}}
{{- if .jobName -}}
  {{- $jobName = printf "--name %s/%s-`cat /var/lib/lily/uid`" .instanceName .jobName -}}
{{- else }}
  {{- $jobName = printf "--name \"%s-`cat /var/lib/lily/uid`/%s\"" .instanceName .command -}}
{{- end -}}
{{- $jobName -}}
{{- end -}}
