{{- define "lotus-lib.container.wallet-importer" }}
- name: wallet-importer
  image: {{ .Values.image }}
  imagePullPolicy: IfNotPresent
  command: [ "bash", "-c" ]
  args:
    - 'while sleep 60; do for key in /wallets/*; do lotus wallet import "${key}" || true; done; done'
  env:
    - name: LOTUS_PATH
      value: /var/lib/lotus
  volumeMounts:
    - name: wallets-secret-volume
      mountPath: /wallets
      readOnly: true
    - name: lotus-path
      mountPath: /var/lib/lotus
      readOnly: true
{{- end }}
