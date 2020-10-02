# Lotus Fullnode

The lotus fullnode chart is designed to be a full featured chart for running a lotus daemon.

## Deployments

### Basic

The basic install provides a pvc for the datastore and generates a secret for the libp2p identify and a secret for the
jwt private key and token. Therefore deleteing the pod results in no loss of data and is similar to just restarting the
container.

```
helm upgrade --install lotus-0 ./lotus-fullnode
```

### Enabling debug container

The debug init container runs last, meaning that there must be success through all previous init containers. The debug
container is exactly the same as the main runtime container except that it will sleep in an infinite loop.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set debug=true
```

### Using external secrets

Both the libp2p and jwt secrets can be managed outside of the chart, and a secret name can be provided. This is in fact the
only way the wallets can be provided to the chart. Be sure to correctly name your secrets key entry according to the default
values, or override them. Please see the `values.yaml` file for more details.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set secrets.libp2p.secretName=my-libp2p-secret --set secrets.jwt.secretName=my-jwt-secret
```

### Using ephemeral secrets

Usually all secrets are going to want to be managed in kubernetes secrets. However, if there is no need for api access
(or just anything above read) or having a static libp2p identify isn't important the generating of these secrets can
be turned off.

The jwt and libp2p secrets can be turned off together or just a single one at a time. When the secrets are disabled
the keys will be generated during the pod init phase and the secrets will be retained through container crashes. However,
they will be removed if the pod is deleted.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set secrets.libp2p.enabled=false --set secrets.jwt.enabled=false
```

### Using import snapshots

This funcitonality requires an installation of the `lotus-chain-export` chart. The `exportRelease` value is the name of the
`lotus-chain-export` release. See the `values.yaml` file for more details.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set importSnapshot.enabled=true --set importSnapshot.exportRelease=<release-name>
```

### Adding wallets

Wallets must be managed externally to the chart. A secret name must be provided along with the key of the secret entry and the
correct keystore encoding of the wallet address. See the `values.yaml` file for more details.

```
helm upgrade --install lotus-0 ./lotus-fullnode -f lotus_secrets_wallets.yaml
```
```
# lotus_secrets_wallets.yaml
secrets:
  wallets:
    enabled: true
    secretName: my-wallets-secret
    keystore:
    - key: t16otcoguwipz3puid6ilsqh26unpdf4iwocnxywa
      path: O5QWY3DFOQWXIMJWN52GG33HOV3WS4D2GNYHK2LEGZUWY43RNAZDM5LOOBSGMNDJO5XWG3TYPF3WC
```

## Rotating secrets

The process of rotating secrets is a bit different depending on how they are configured.

### Rotating jwt secrets created by the chart
_This is the default behavior of the chart_

```
1. delete the secret and the job which creates it
$ kubectl delete secret <release-name>-jwt-secrets
$ kubectl delete job    <release-name>-jwt-secrets-creator
2. run a chart upgrade, this will recreate the releases secrets-creator job, which in result will create a new secret
$ helm upgrade <release-name> ./lotus-fullnode ....
3. delete the pod
$ kubectl delete pod <release-name>-0
```

### Rotating libp2p secrets created by the chart
_This is the default behavior of the chart_

```
1. delete the secret and the job which creates it
$ kubectl delete secret <release-name>-libp2p-secrets
$ kubectl delete job    <release-name>-libp2p-secrets-creator
2. run a chart upgrade, this will recreate the releases secrets-creator job, which in result will create a new secret
$ helm upgrade <release-name> ./lotus-fullnode ....
3. delete the pod
$ kubectl delete pod <release-name>-0
```
