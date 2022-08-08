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
    {{- include "sentinel-lily.allLabels" $root | nindent 4 }}
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
      {{- include "sentinel-lily.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "sentinel-lily.allLabels" $root | nindent 8 }}
    spec:
      {{- include "sentinel-lily.common-lily-affinity-selectors" $root | indent 6 }}
      imagePullSecrets:
      - name: regcred
      initContainers:
      - name: init-datastore
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c"]
        args:
        {{- include "sentinel-lily.initialize-datastore-script" $root | nindent 10 }}
        env:
        {{- include "sentinel-lily.common-envvars" $root | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" $root | indent 8 }}
        resources:
          # resources required to initialize the datastore are small
          {{- include "sentinel-lily.minimal-resources" $root.Values.debug.resources | indent 10 }}
      - name: init-sync
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c"]
        args:

        env:
        {{- include "sentinel-lily.common-envvars" $root | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" $root | indent 8 }}
        resources:
          # resources required to initialize the datastore are small
          {{- include "sentinel-lily.minimal-resources" $root | indent 10 }}
      containers:
      {{- if $root.Values.debug.enabled }}
      - name: debug
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["/bin/sh", "-c", "tail -f /dev/null"]
        env:
        {{- include "sentinel-lily.common-envvars" $root | indent 8 }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" $root | indent 8 }}
        resources:
        {{- if $root.Values.debug.resources }}
          {{- include "sentinel-lily.minimal-resources" $root.Values.debug.resources | nindent 10 }}
        {{- else }}
          requests:
            cpu: "1000m"
            memory: "4Gi"
          limits:
            cpu: "1000m"
            memory: "4Gi"
        {{- end }}
      {{- end }}
      - name: daemon
        image: {{ include "sentinel-lily.docker-image" $root | quote }}
        imagePullPolicy: {{ $root.Values.image.pullPolicy | quote }}
        command: ["lily"]
        args:
        - daemon
        {{- range $root.Values.daemon.args }}
        - {{ $root }}
        {{- end }}
        env:
        {{- include "sentinel-lily.common-envvars" $root | indent 8 }}
        ports:
        - containerPort: 1234
          name: api
        - containerPort: 1347
          name: p2p
        {{- if $root.Values.prometheusOperatorServiceMonitor }}
        - containerPort: 9991
          name: metrics
        {{- end }}
        volumeMounts:
        {{- include "sentinel-lily.common-volume-mounts" $root | indent 8 }}
        lifecycle:
          postStart:
            exec:
              command:
                {{- include "sentinel-lily.common-job-start-script" (list $root $instanceType ) | nindent 16 }}
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
      {{- include "sentinel-lily.volume-mounts" $root | indent 6 }}
  volumeClaimTemplates:
  {{- if eq $instanceType "daemon" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.daemon.volumes.datastore | indent 4 }}
  {{- else if eq $instanceType "notifier" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.cluster.notifier.volumes.datastore | indent 4 }}
  {{- else if eq $instanceType "worker" }}
  {{- include "sentinel-lily.volume-claim-templates" $root.Values.cluster.worker.volumes.datastore | indent 4 }}
  {{- end }}
{{- end -}}
