{{- define "lotus-lib.container.reset-datastore" }}
{{- $resetDatastore := (index .Values "reset-datastore") -}}
{{- $resetContext := (
  dict
    "Values"   $resetDatastore
    "Chart"    $.Chart
    "Template" $.Template
    "Release"  $.Release
  ) 
-}}

{{ include "lotus-lib.fragments.mainContainer" $resetContext }}
{{- end -}}