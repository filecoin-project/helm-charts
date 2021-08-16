{{/* "sentinel-visor.name" is "instanceName" truncated for use within k8s values */}}
{{- define "sentinel-visor.name" -}}
{{- (include "sentinel-visor.instanceName" . ) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* "sentinel-visor.instanceName" is generates a descriptive name of the instance based on release values or release.nameOverride */}}
{{- define "sentinel-visor.instanceName" -}}
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

{{- /* Common labels */}}
{{- define "sentinel-visor.labels" -}}
{{ include "sentinel-visor.selectorLabels" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
heritage: {{ .Release.Service }}
app: visor
suite: sentinel
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: sentinel
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}

{{- /* Selector labels */}}
{{- define "sentinel-visor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentinel-visor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
release: {{ .Release.Name }}
{{- end }}

{{- /* Starts snapshot import within import-snapshot init container. */}}
{{- define "sentinel-visor.chain-import-as-args" }}
  if [ -f "/var/lib/visor/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/visor/datastore/_imported file."
    echo "Ensuring secrets have correct permissions."
    chmod 0600 /var/lib/visor/keystore/*
    exit 0
  fi
  echo "Importing snapshot from url {{ .Values.daemon.importSnapshot.url }}..."
  visor init --import-snapshot={{ .Values.daemon.importSnapshot.url }}
  status=$?
  if [ $status -eq 0 ]; then
    touch "/var/lib/visor/datastore/_imported"
  fi
  echo "Ensuring secrets have correct permissions."
  chmod 0600 /var/lib/visor/keystore/*
  exit $status
{{- end }}

{{- /* Helpers */}}
{{/* "sentinel-visor.jaegerTracingEnvvars" creates the envvars for supporting jaeger tracing */}}
{{- define "sentinel-visor.jaegerTracingEnvvars" -}}
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
  value: {{ .Values.jaeger.serviceName | default (include "sentinel-visor.instanceName" . ) | quote }}
- name: JAEGER_SAMPLER_TYPE
  value: {{ .Values.jaeger.sampler.type | default "probabilistic" | quote }}
- name: JAEGER_SAMPLER_PARAM
  value: {{ .Values.jaeger.sampler.param | default "0.0001" | quote }}
{{- end }}
{{- end }}
