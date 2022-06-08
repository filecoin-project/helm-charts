{{/*
Expand the name of the chart.
*/}}
{{- define "filecoin-chain-archiver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "filecoin-chain-archiver._priv.snapshots.logLevelNamed" -}}
{{- range .Values.snapshots.logging.named }}{{(print .logger ":" .level ) }},{{- end }}
{{- end }}

{{- define "filecoin-chain-archiver.snapshots.logLevelNamed" -}}
{{- if .Values.snapshots.logging.named }}
{{- (include "filecoin-chain-archiver._priv.snapshots.logLevelNamed" .) | trimSuffix "," }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "filecoin-chain-archiver.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "filecoin-chain-archiver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "filecoin-chain-archiver.labels" -}}
helm.sh/chart: {{ include "filecoin-chain-archiver.chart" . }}
{{ include "filecoin-chain-archiver.selectorLabels" . }}
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
{{- define "filecoin-chain-archiver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "filecoin-chain-archiver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "filecoin-chain-archiver.snapshots.serviceAccountName" -}}
{{- if .Values.snapshots.serviceAccount.create }}
{{- default (include "filecoin-chain-archiver.fullname" .) .Values.snapshots.serviceAccount.name }}
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
{{- printf "%s-%s" (include "filecoin-chain-archiver.fullname" . ) "s3" }}
{{- end }}
{{- end }}
