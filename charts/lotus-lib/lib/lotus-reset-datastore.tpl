{{- define "lotus-lib.container.reset-datastore" }}
name: reset-datastore
image: {{ .Values.image }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
command: [ "bash", "-c" ]
args:
- |
  set -xeou pipefail
  pct=$(df -h $LOTUS_PATH | awk '/[0-9]+%/ {print substr($5, 1, length($5)-1)}')
  echo "reset percentage is $RESET_PERCENTAGE"
  echo "The datastore is $pct% full"
  if [[ "$pct" -lt "$RESET_PERCENTAGE" ]]
  then
    echo "not resetting"
  else
    echo "resetting datastore."
    rm -rf "${LOTUS_PATH}/datastore" || echo "datastore does not exist"
  fi
env:
- name: LOTUS_PATH
  value: /var/lib/lotus
- name: RESET_PERCENTAGE
  value: "{{ toString .Values.reset.percent }}"
volumeMounts:
- name: lotus-path
  mountPath: /var/lib/lotus
{{- end -}}