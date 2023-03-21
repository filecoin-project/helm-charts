{{- define "lotus-lib.container.lotus" }}
name: {{ .Values.name }}
image: {{ .Values.image }}
imagePullPolicy: {{ .Values.imagePullPolicy }}

{{ # Environment Variables }}
{{- include "lotus-lib.env_vars" (dict "Values" .Values "Template" $.Template) }}

{{ # Resources }}
{{- if .Values.resources }}
resources:
  {{- if .Values.lite.enabled }}
    {{ .Values.lite.resouces | toYaml | indent 2 }}
  {{- else }}
    {{ .Values.resouces | toYaml | indent 2 }}
  {{- end }}
{{- end -}}

{{ # Volumes }}
{{- if .Values.volumeMounts }}
volumeMounts:
{{ .Values.volumeMounts | toYaml }}
{{- end }}

command: [ "bash", "-c" ]
args:
  - |
    chmod -R o-r $LOTUS_PATH
    chmod -R o-w $LOTUS_PATH
    chmod -R g-r $LOTUS_PATH
    chmod -R g-w $LOTUS_PATH
    /usr/local/bin/lotus daemon {{ if .Values.lite.enabled }}--lite {{ end }}
ports:
- containerPort: 1234
  name: lotus-api
{{- end }}
