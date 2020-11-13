# Lotus Secrets Creator

The lotus secrets creator is a chart tool to help generate valid secrets for the lotus fullnode chart.

## Deployments

### Basic

The basic install will not do anything. You must enabled the secrets you want to create. Please see the `values.yaml`
for more information.

**Creating jwt secrets**

```
$ helm upgrade --install lotus-0-secrets ./lotus-secrets-creator --set secrets.jwt.enabled=true --set secrets.jwt.secretName=lotus-0-jwt-secrets
```

**Creating libp2p secrets**

```
$ helm upgrade --install lotus-0-secrets ./lotus-secrets-creator --set secrets.libp2p.enabled=true --set secrets.libp2p.secretName=lotus-0-libp2p-secrets
```
