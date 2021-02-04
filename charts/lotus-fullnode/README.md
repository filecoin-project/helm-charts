# Lotus Fullnode

The lotus fullnode chart is designed to be a full featured chart for running a lotus daemon.

## Deployments

### Basic

The basic install provides a pvc for the datastore and generates temporary secrets for the libp2p identify and for the
jwt private key and token. Therefore deleteing the pod results in loss of these secrets. For this reason we recommend
that secrets are generated externally and a secret named is supplied. See `Using external secrets`.

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

You can also use the `lotus-secrets-creator` chart to generate these secrets for you.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set secrets.libp2p.secretName=my-libp2p-secret --set secrets.jwt.secretName=my-jwt-secret --set secrets.jwt.enabled=true --set secrets.libp2p.enabled=true
```

### Using import snapshots

This funcitonality requires an installation of the `lotus-chain-export` chart. The `exportRelease` value is the name of the
`lotus-chain-export` release. See the `values.yaml` file for more details.

```
helm upgrade --install lotus-0 ./lotus-fullnode --set importSnapshot.enabled=true --set importSnapshot.exportRelease=<release-name>
```

### Adding wallets

Wallets must be managed externally to the chart. A secret name must be provided, all entries in the secret will be treated as a wallet.

The secret key should be the name of the wallet, and the value should be the base64 enocded contents of the keyinfo file
```
$ lotus-shed keyinfo new bls
t3u5bz4yb6mriqbbpx5mif6fodmobr3a5vi5gjyxsfp6xs7um3coruzhowj6eqlvv6hd7gts5mue56f7knzrdq
$ kubectl create secret generic my-wallets-secret --from-file=t3u5bz4yb6mriqbbpx5mif6fodmobr3a5vi5gjyxsfp6xs7um3coruzhowj6eqlvv6hd7gts5mue56f7knzrdq=bls-t3u5bz4yb6mriqbbpx5mif6fodmobr3a5vi5gjyxsfp6xs7um3coruzhowj6eqlvv6hd7gts5mue56f7knzrdq.keyinfo
```

```
helm upgrade --install lotus-0 ./lotus-fullnode -f lotus_secrets_wallets.yaml
```

```
# lotus_secrets_wallets.yaml
secrets:
  wallets:
    enabled: true
    secretName: my-wallets-secret
```
