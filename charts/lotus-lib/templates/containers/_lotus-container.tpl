{{- define "lotus-lib.container.lotus.resources" }}
{{/* Choose resources depending on if lite mode is enabled */}}
{{ $lotus := .Values.lotus }}
{{- if $lotus.resources }}
  {{- if $lotus.lite.enabled }}
    {{ $lotus.lite.resouces | toYaml | indent 2 }}
  {{- else }}
    {{ $lotus.resouces | toYaml | indent 2 }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "lotus-lib.container.lotus.args" -}}
|
      chmod -R o-r $LOTUS_PATH
      chmod -R o-w $LOTUS_PATH
      chmod -R g-r $LOTUS_PATH
      chmod -R g-w $LOTUS_PATH
      /usr/local/bin/lotus daemon {{ if .Values.lotus.lite.enabled }}--lite {{ end }}
{{- end -}}

{{- define "lotus-lib.container.lotus" }}
{{- $lotus := .Values.lotus -}}
{{- $lotusContext :=
  (dict "Values" $lotus "Chart" $.Chart "Template" $.Template "Release" $.Release) 
-}}
{{- $_ := set $lotus "resources" (include "lotus-lib.container.lotus.resources" . | fromYaml) -}}
{{- $_ := set $lotus "args" (include "lotus-lib.container.lotus.args" . ) -}}

{{ include "lotus-lib.fragments.mainContainer" 
  (dict "Values" $lotus "Chart" $.Chart "Template" $.Template "Release" $.Release) 
}}
{{- end -}}