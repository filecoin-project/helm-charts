# Lotus Secrets Creator

The lotus secrets creator is a chart tool to help generate valid secrets for the lotus fullnode chart.

## Deployments

### Basic

This chart by default will generate both libp2p and jwt secrets using the name of the helm release. It's adviced to not use this behavior
has it makes updating secrets more difficult. You should instead specify the fullname of the secret instead as shown below.

**Creating jwt secrets**

```
$ helm upgrade --install lotus-0-secrets ./lotus-secrets-creator --set secrets.jwt.enabled=true --set secrets.jwt.secretName=lotus-0-jwt-secrets
```

**Creating libp2p secrets**

```
$ helm upgrade --install lotus-0-secrets ./lotus-secrets-creator --set secrets.libp2p.enabled=true --set secrets.libp2p.secretName=lotus-0-libp2p-secrets
```
