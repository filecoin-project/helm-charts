{{/*
    template for creating a lily stateful set
*/}}
{{- define "sentinel-lily.lily-app-template" -}}
{{- $instanceType := index . 0 -}}
{{- $root := index . 1 -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ list ( include "sentinel-lily.short-instance-name" $root ) $instanceType | join "-" | quote }}
  labels:
    {{- if eq $instanceType "notifier" -}}
    {{- include "sentinel-lily.notifierAllLabels" $root | nindent 4 }}
    {{- else if eq $instanceType "worker" -}}
    {{- include "sentinel-lily.workerAllLabels" $root | nindent 4 }}
    {{- else -}}
    {{- include "sentinel-lily.allLabels" $root | nindent 4 }}
    {{- end }}
spec:
  {{- if eq $instanceType "notifier" }}
  replicas: 1
  {{- else }}
  replicas: {{ $root.Values.replicaCount | default 1 }}
  {{- end }}
  serviceName: {{ include "sentinel-lily.short-instance-name" $root }}-{{ $instanceType }}-lily-api
  podManagementPolicy: {{ $root.Values.podManagementPolicy | default "Parallel" | quote }}
  selector:
    matchLabels:
      {{- if eq $instanceType "notifier" -}}
      {{- include "sentinel-lily.notifierSelectorLabels" $root | nindent 6 }}
      {{- else if eq $instanceType "worker" -}}
      {{- include "sentinel-lily.workerSelectorLabels" $root | nindent 6 }}
      {{- else -}}
      {{- include "sentinel-lily.selectorLabels" $root | nindent 6 }}
      {{- end }}
  template:
    metadata:
      labels:
        {{- if eq $instanceType "notifier" -}}
        {{- include "sentinel-lily.notifierAllLabels" $root | nindent 8 }}
        {{- else if eq $instanceType "worker" -}}
        {{- include "sentinel-lily.workerAllLabels" $root | nindent 8 }}
        {{- else -}}
        {{- include "sentinel-lily.allLabels" $root | nindent 8 }}
        {{- end }}
    spec:
      {{- include "sentinel-lily.common-lily-affinity-selectors" $root | indent 6 }}
      imagePullSecrets:
      - name: regcred
      terminationGracePeriodSeconds: 60
      initContainers:
      - name: init-datastore
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c"]
        args:
        {{- include "sentinel-lily.initialize-datastore-script" $root | nindent 10 }}
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" ( list $root $instanceType ) | nindent 8 }}
        {{- if $root.Values.importSnapshot.gcloudCredentials }}
        - name: "gcloud-config"
          mountPath: "/root/.config/gcloud"
        - name: "gcloud-credentials"
          mountPath: "/root/.config/gcloud/application_default_credentials.json"
          subPath: "application_default_credentials.json"
        {{- end }}
        resources:
          {{- /* empty dict to use defaults */ -}}
          {{- include "sentinel-lily.resources" dict | indent 10 }}
      {{- if not $root.Values.debug.disableNetworkSync }}
      - name: init-sync
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Starting daemon..."
          lily daemon &
          daemonID=$!

          echo "Waiting for network sync to complete..."
          lily wait-api --timeout={{ $root.Values.apiWaitTimeout | quote }} > /dev/null 2>&1
          status=$?
          if [ $status -ne 0 ]; then
            echo "exit with code $status"
            exit $status
          fi

          lily sync wait
          status=$?
          if [ $status -ne 0 ]; then
            echo "exit with code $status"
            exit $status
          fi

          kill -15 $daemonID
          status=$?
          if [ $status -ne 0 ]; then
            echo "exit with code $status"
            exit $status
          fi
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" ( list $root $instanceType ) | nindent 8 }}
        resources:
          {{- /* empty dict to use defaults */ -}}
          {{- include "sentinel-lily.resources" dict | indent 10 }}
      {{- end }}
      {{- if or $root.Values.daemon.storage.postgresql $root.Values.cluster.storage.postgresql }}
      - name: init-database
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c"]
        args:
        - |
        {{- if and ( eq $instanceType "daemon" ) -}}
          {{- /* check all daemon storage targets */ -}}
          {{- range $root.Values.daemon.storage.postgresql }}
          echo "Checking for database readiness for {{ .name }}..."
          LILY_DB=$LILY_STORAGE_POSTGRESQL_{{ .name | upper }}_URL lily migrate --schema {{ .schema | quote }}
          {{- end }}
        {{- else }}
          {{- /* check all cluster storage targets */ -}}
          {{- range $root.Values.cluster.storage.postgresql }}
          echo "Checking for database readiness for {{ .name }}..."
          LILY_DB=$LILY_STORAGE_POSTGRESQL_{{ .name | upper }}_URL lily migrate --schema {{ .schema | quote }}
          {{- end }}
        {{- end }}
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" ( list $root $instanceType ) | nindent 8 }}
        resources:
          requests:
            cpu: "1000m"
            memory: "1Gi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
      {{- end }}
      {{- /* only check redis readiness for cluster configurations */ -}}
      {{- if ne $instanceType "daemon" }}
      - name: init-redis
        image: bitnami/redis:7.0
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/bash", "-c"]
        args:
        - |
          export REDISCLI_AUTH="$LILY_REDIS_PASSWORD"
          response=$(
            timeout -s 3 10 \
            redis-cli \
              -u redis://$LILY_REDIS_ADDR \
              ping
          )
          if [ "$?" -eq "124" ]; then
            echo "Timed out"
            exit 1
          fi
          responseFirstWord=$(echo $response | head -n1 | awk '{print $1;}')
          if [ "$response" != "PONG" ] && [ "$responseFirstWord" != "LOADING" ] && [ "$responseFirstWord" != "MASTERDOWN" ]; then
            echo "$response"
            exit 1
          fi
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        resources:
          requests:
            cpu: "1000m"
            memory: "1Gi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
      {{- end }}
      containers:
      {{- if $root.Values.debug.sidecar.enabled }}
      - name: debug
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c", "tail -f /dev/null"]
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" ( list $root $instanceType ) | nindent 8 }}
        resources:
          {{- include "sentinel-lily.resources" $root.Values.debug.sidecar.resources | indent 10 }}
      {{- end }}
      - name: daemon
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["lily"]
        args:
        - daemon
        {{- if eq $instanceType "daemon" }}
        {{- range $root.Values.daemon.args }}
        - {{ . }}
        {{- end }}
        {{- else if eq $instanceType "notifier" }}
        {{- range $root.Values.cluster.notifier.args }}
        - {{ . }}
        {{- end }}
        {{- else if eq $instanceType "worker" }}
        {{- range $root.Values.cluster.worker.args }}
        - {{ . }}
        {{- end }}
        {{- end }}
        {{- if $root.Values.debug.disableNetworkSync }}
        - --bootstrap=false
        {{- end }}
        env:
        {{- include "sentinel-lily.common-envvars" ( list $instanceType $root ) | indent 8 }}
        ports:
        - containerPort: 1234
          name: "api"
        - containerPort: 1347
          name: "p2p"
        {{- if $root.Values.prometheusOperatorServiceMonitor }}
        - containerPort: 9991
          name: "metrics"
        {{- end }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" ( list $root $instanceType ) | nindent 8 }}
        lifecycle:
          postStart:
            exec:
              command:
                {{- include "sentinel-lily.common-job-start-script" (list $root $instanceType ) | indent 16 }}
        resources:
          {{- if eq $instanceType "daemon" -}}
          {{- include "sentinel-lily.app-resources" $root.Values.daemon.resources | indent 10 }}
          {{- else if eq $instanceType "notifier" -}}
          {{- include "sentinel-lily.app-resources" $root.Values.cluster.notifier.resources | indent 10 }}
          {{- else if eq $instanceType "worker" -}}
          {{- include "sentinel-lily.app-resources" $root.Values.cluster.worker.resources | indent 10 }}
          {{- else -}}
          requests:
            cpu: "16000m"
            memory: "225Gi"
          limits:
            cpu: "16000m"
            memory: "225Gi"
          {{- end }}
      volumes:
      {{- include "sentinel-lily.volume-mappings" ( list $root $instanceType ) | nindent 6 }}
      {{- if $root.Values.importSnapshot.gcloudCredentials }}
      - name: "gcloud-config"
        emptyDir: {}
      - name: "gcloud-credentials"
        secret:
          secretName: {{ $root.Values.importSnapshot.gcloudCredentials.serviceAccountKey.secretName | default "gcloud-credentials" | quote }}
          optional: false
          items:
          - key: {{ $root.Values.importSnapshot.gcloudCredentials.serviceAccountKey.secretKey | default "gcloud-credentials.json" | quote }}
            path: "application_default_credentials.json"
      {{- end }}

  volumeClaimTemplates:
  {{- if eq $instanceType "daemon" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.daemon.volumes.datastore | indent 4 }}
  {{- else if eq $instanceType "notifier" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.cluster.notifier.volumes.datastore | indent 4 }}
  {{- else if eq $instanceType "worker" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.cluster.worker.volumes.datastore | indent 4 }}
  {{- end }}
{{- end -}}
