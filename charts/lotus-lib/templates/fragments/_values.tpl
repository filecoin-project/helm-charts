{{/* Merge the local chart values and the common chart defaults */}}
{{- define "lotus-lib.values.setup" -}}
  {{- if (index .Values "lotus-lib") -}}
    {{- $defaultValues := deepCopy (index .Values "lotus-lib") -}}
    {{- $userValues := deepCopy (omit .Values "lotus-lib") -}}
    {{- $mergedValues := mustMergeOverwrite $defaultValues $userValues -}}
    {{- $_ := set . "Values" (deepCopy $mergedValues) -}}
  {{- end -}}
{{- end -}}
