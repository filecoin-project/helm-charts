# Lotus Grafana

This chart is basically a grafana chart with a few comfigmaps to be loaded into a nginx sidecar container
to restrict access to a single dashboard in kiosk mode.

### Getting Access to grafana

```
kubectl get secret <grafana> -o json | jq -r '.data["admin-password"]' | base64 -d
kubectl get secret <grafana> -o json | jq -r '.data["admin-user"]' | base64 -d
kubectl port-forward pod/<grafana-pod> 3000:3000
```


### Examples values

Create a configmap from `https://github.com/filecoin-project/lotus/blob/master/cmd/lotus-stats/chain.dashboard.json`
```
kubectl create configmap chainstats-dashboard --from-file chain.dashboard.json
```

Create secret for influxdb password
```
kubectl create secret generic datasource-secrets --from-literal=INFLUXDB_PASSWORD="password"
```

Example values
```
domain: stats.butterfly.fildev.network
mainDashboardID: z6FtI92Zz               # sourced from chain.dashboard.json
mainDashboardSlug: filecoin-chain-stats  # sourced from chain.dashboard.json

grafana:
  image:
    tag: 7.2.1

  envFromSecret: "datasource-secrets"

  persistence:
    enabled: false

  dashboardsConfigMaps:
    default: "chainstats-dashboard"

  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: true
        editable: false
        options:
          path: /var/lib/grafana/dashboards/default

  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: ntwk-butterflynet                                 # must match /^ntwk-/
        type: influxdb
        access: proxy
        database: chainstats-ntwk-butterflynet                  # update
        user: lotus-grafana
        url: https://influxdb:8086                              # update
        jsonData:
          httpMode: POST
        secureJsonData:
          password: $INFLUXDB_PASSWORD                          # populated at runtime via `envFromSecret`

  # nginx side car configuration

  extraConfigmapMounts:
  - configMap: butterfly-stats-nginx-sidecar                    # must match helm release name
    mountPath: /opt/bitnami/nginx/conf/grafana-restricted
    subPath: ''
    name: config-volume
    readOnly: true

  extraContainers: |
    - image: bitnami/nginx:1.16
      name: nginx
      ports:
      - containerPort: 8000
      securityContext:
        allowPrivilegeEscalation: false
        runAsUser: 0
      volumeMounts:
      - mountPath: /opt/bitnami/nginx/conf/grafana-restricted
        name: config-volume
        readOnly: true

  # Some annotiation will need to be added for certs
  service:
    port: 443
    portName: https
    targetPort: 8000
    type: LoadBalancer
```
