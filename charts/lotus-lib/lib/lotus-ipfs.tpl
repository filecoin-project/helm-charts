{{- define "lotus-lib.container.ipfs" }}
name: ipfs
image: {{ .Values.image }}
imagePullPolicy: {{ .Values.imagePullPolicy }}
ports:
  - protocol: TCP
    containerPort: 4001
    name: libp2p-tcp
  - protocol: UDP
    containerPort: 4001
    name: libp2p-udp
  - protocol: TCP
    containerPort: 8081
    name: libp2p-ws
volumeMounts:
  - name: ipfs-path
    mountPath: /data/ipfs
{{- end }}

