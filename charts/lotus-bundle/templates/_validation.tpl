{{- define "lotus-bundle.validate.sts" }}
  {{- if .Values.lotus.lite.enabled }}
  {{- $lotusEnvs := mergeOverwrite .Values.lotus.env (default .Values.lotus.extraEnv dict) -}}
    {{ if  (hasKey $lotusEnvs "FULLNODE_API_INFO") }}
    {{ else }}
      {{- fail (
        "FULLNODE_API_INFO environment variable must be supplied in either lotus.env "
        "or lotus.extraEnv when lotus.lite.enabled is true")
      }}
    {{ end }}
  {{- end }}
{{- end }}

