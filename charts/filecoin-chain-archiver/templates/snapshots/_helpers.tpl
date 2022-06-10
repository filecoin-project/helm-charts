{{- define "filecoin-chain-archiver.snapshots.fullname" -}}
{{- printf "%s-%s" (include "filecoin-chain-archiver.fullname" . ) "snapshots" }}
{{- end }}

{{- define "filecoin-chain-archiver.internal.snapshots.logLevelNamed" -}}
{{- range .Values.snapshots.logging.named }}{{(print .logger ":" .level ) }},{{- end }}
{{- end }}

{{- define "filecoin-chain-archiver.snapshots.logLevelNamed" -}}
{{- if .Values.snapshots.logging.named }}
{{- (include "filecoin-chain-archiver.internal.snapshots.logLevelNamed" .) | trimSuffix "," }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "filecoin-chain-archiver.snapshots.labels" -}}
helm.sh/chart: {{ include "filecoin-chain-archiver.chart" . }}
{{ include "filecoin-chain-archiver.snapshots.selectorLabels" . }}
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
{{- define "filecoin-chain-archiver.snapshots.selectorLabels" -}}
app.kubernetes.io/name: {{ include "filecoin-chain-archiver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: snapshots
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "filecoin-chain-archiver.snapshots.serviceAccountName" -}}
{{- if .Values.snapshots.serviceAccount.create }}
{{- default (include "filecoin-chain-archiver.snapshots.fullname" . ) .Values.snapshots.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.snapshots.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the secret to use for uploads
*/}}
{{- define "filecoin-chain-archiver.snapshots.secretName" -}}
{{- if .Values.snapshots.uploads.secretName }}
{{- .Values.snapshots.uploads.secretName }}
{{- else }}
{{- printf "%s-%s" (include "filecoin-chain-archiver.snapshots.fullname" . ) "s3" }}
{{- end }}
{{- end }}
