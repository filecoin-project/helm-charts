{{- /* Starts snapshot import within import-snapshot init container. */}}
{{- define "sentinel-visor.chain-import-as-args" }}
  if [ -f "/var/lib/visor/datastore/_imported" ]; then
    echo "Skipping import, found /var/lib/visor/datastore/_imported file."
    echo "Ensuring secrets have correct permissions."
    chmod 0600 /var/lib/visor/keystore/*
    exit 0
  fi
  echo "Importing snapshot from url {{ .Values.daemon.importSnapshot.url }}..."
  visor init --import-snapshot={{ .Values.daemon.importSnapshot.url }}
  status=$?
  if [ $status -eq 0 ]; then
    touch "/var/lib/visor/datastore/_imported"
  fi
  echo "Ensuring secrets have correct permissions."
  chmod 0600 /var/lib/visor/keystore/*
  exit $status
{{- end }}

{{- /* Starts daemon jobs when daemon is ready. */}}
{{- define "sentinel-visor.start-jobs-as-args" }}
  echo "Waiting for api to become ready..."
  visor wait-api --timeout=60s
  status=$?
  if [ $status -ne 0 ]; then
    exit $status
  fi
  echo "Starting jobs..."
  {{- range .Values.daemon.jobs }}
  visor {{ .command }} {{ join " " .args }}
  {{- end }}
{{- end }}
