{{- define "lotus-lib.container.shared-storage-preparer" }}
name: shared-storage-preparer
image: {{ .Values.image }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
securityContext:
runAsUser: 0
command: [ "bash", "-c" ]
args:
- |
  {{- range $vol := .Values.application.storage }}
  {{- if $vol.subdirPerRelease }}
  mkdir -p {{ $vol.mount }}/{{ $.Release.Namespace }}/{{ $.Release.Name }}
  {{- if $vol.chownLotus }}
  chown fc {{ $vol.mount }}/{{ $.Release.Namespace }}/{{ $.Release.Name }}
  {{- end }}
  {{- else }}
  {{- if $vol.chownLotus }}
  chown fc {{ $vol.mount }}
  {{- end }}
  {{- end }}
  {{- end }}
volumeMounts:
{{- range $st := $.Values.application.storage }}
{{- $vol := index $st.volume 0 }}
- name: {{ $vol.name }}
  mountPath: {{ $st.mount }}
{{- end }}
