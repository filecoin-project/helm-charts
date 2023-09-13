{{- /* The main container included in the fragments */ -}}
{{- define "lotus-lib.fragments.mainContainer" -}}
- {{ if .Values.name -}}
  name: {{ .Values.name }}
  {{- else -}}
  name: {{ include "lotus-lib.names.fullname" . }}
  {{ end }}
  image: {{ printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) | quote }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- with .Values.command }}
  command:
    {{- if kindIs "string" . }}
    - {{ . }}
    {{- else -}}
      {{ toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with .Values.args }}
  args:
    {{- if kindIs "string" . }}
    - {{ . }}
    {{- else -}}
    {{ toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with .Values.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (default .Values.termination dict).messagePath }}
  terminationMessagePath: {{ . }}
  {{- end }}
  {{- with (default .Values.termination dict).messagePolicy }}
  terminationMessagePolicy: {{ . }}
  {{- end }}

  {{- with .Values.env }}
  env:
    {{- get (fromYaml (include "lotus-lib.fragments.env_vars" $)) "env" | toYaml | nindent 4 -}}
  {{- end }}
  {{- if or .Values.envFrom .Values.secret }}
  envFrom:
    {{- with .Values.envFrom }}
      {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if .Values.secret }}
    - secretRef:
        name: {{ include "lotus-lib.names.fullname" . }}
    {{- end }}
  {{- end }}
  {{- with .Values.ports }}
  ports: {{ . | toYaml | nindent 2 }}
  {{- end }}
  {{- with .Values.volumeMounts }}
  volumeMounts: {{ toYaml . | nindent 2 }}
  {{- end }}
  {{- with .Values.probes }}
  probes: {{ toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
