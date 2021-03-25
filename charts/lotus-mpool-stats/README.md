# Lotus Mpool Stats

Lotus Mpool Stats deploys a daemon which aggregates mpool stats for consumption by a prometheus service.

## Deployments

### Basic

See the `values.yaml` for how to name the secret and the required values.

```
helm upgrade --install lotus-mpool-stats ./lotus-mpool-stats --set lotusApiInfo=/dns/fullnode-0-lotus-daemon.default.svc.cluster.local/tcp/1234
```
_using a `lotus-fullnode` deployment named `fullnode-0`_
