{{/*
Expand the name of the chart.
*/}}
{{- define "sentinel-visor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
