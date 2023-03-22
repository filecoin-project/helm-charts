{{- define "lotus-lib.container.snapshot-importer" }}
name: snapshot-importer
image: {{ .Values.image }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
command: [ "bash", "-c" ]
args:
- |
  set -xeou pipefail
  GATE="$LOTUS_PATH"/datastore/date_initialized
  # Don't init if already initialized.
  if [ ! -f "$GATE" ]; then
    echo importing minimal snapshot
    /usr/local/bin/lotus daemon --import-snapshot "$DOCKER_LOTUS_IMPORT_SNAPSHOT" --halt-after-import
    # Block future inits
    date > "$GATE"
  fi
env:
- name: LOTUS_PATH
  value: /var/lib/lotus
- name: DOCKER_LOTUS_IMPORT_SNAPSHOT
  value: https://snapshots.mainnet.filops.net/minimal/latest
volumeMounts:
- name: lotus-path
  mountPath: /var/lib/lotus
- name: parameter-cache
  mountPath: /var/tmp/filecoin-proof-parameters
{{- end -}}