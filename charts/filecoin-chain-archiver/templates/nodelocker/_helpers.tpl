{{- define "filecoin-chain-archiver.nodelocker.fullname" -}}
{{- printf "%s-%s" (include "filecoin-chain-archiver.fullname" . ) "nodelocker" }}
{{- end }}

{{- define "filecoin-chain-archiver.internal.nodelocker.logLevelNamed" -}}
{{- range .Values.nodelocker.logging.named }}{{(print .logger ":" .level ) }},{{- end }}
{{- end }}

{{- define "filecoin-chain-archiver.nodelocker.logLevelNamed" -}}
{{- if .Values.nodelocker.logging.named }}
{{- (include "filecoin-chain-archiver.internal.nodelocker.logLevelNamed" .) | trimSuffix "," }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "filecoin-chain-archiver.nodelocker.labels" -}}
helm.sh/chart: {{ include "filecoin-chain-archiver.chart" . }}
{{ include "filecoin-chain-archiver.nodelocker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "filecoin-chain-archiver.nodelocker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "filecoin-chain-archiver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: nodelocker
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "filecoin-chain-archiver.nodelocker.serviceAccountName" -}}
{{- if .Values.nodelocker.serviceAccount.create }}
{{- default (include "filecoin-chain-archiver.nodelocker.fullname" . ) .Values.nodelocker.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nodelocker.serviceAccount.name }}
{{- end }}
{{- end }}
