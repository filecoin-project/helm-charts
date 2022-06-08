{{- define "filecoin-chain-archiver.index-resolver.fullname" -}}
{{- printf "%s-%s" (include "filecoin-chain-archiver.fullname" . ) "index-resolver" }}
{{- end }}

{{- define "filecoin-chain-archiver.internal.index-resolver.logLevelNamed" -}}
{{- range .Values.indexResolver.logging.named }}{{(print .logger ":" .level ) }},{{- end }}
{{- end }}

{{- define "filecoin-chain-archiver.index-resolver.logLevelNamed" -}}
{{- if .Values.indexResolver.logging.named }}
{{- (include "filecoin-chain-archiver.internal.index-resolver.logLevelNamed" .) | trimSuffix "," }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "filecoin-chain-archiver.index-resolver.labels" -}}
helm.sh/chart: {{ include "filecoin-chain-archiver.chart" . }}
{{ include "filecoin-chain-archiver.index-resolver.selectorLabels" . }}
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
{{- define "filecoin-chain-archiver.index-resolver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "filecoin-chain-archiver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: index-resolver
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "filecoin-chain-archiver.index-resolver.serviceAccountName" -}}
{{- if .Values.indexResolver.serviceAccount.create }}
{{- default (include "filecoin-chain-archiver.index-resolver.fullname" . ) .Values.indexResolver.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.indexResolver.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the secret to use for uploads
*/}}
{{- define "filecoin-chain-archiver.index-resolver.secretName" -}}
{{- if .Values.indexResolver.s3Resolver.secretName }}
{{- .Values.indexResolver.s3Resolver.secretName }}
{{- else }}
{{- printf "%s-%s" (include "filecoin-chain-archiver.index-resolver.fullname" . ) "s3" }}
{{- end }}
{{- end }}
