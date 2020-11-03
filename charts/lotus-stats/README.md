# Lotus Stats

The lotus stats chart provides the chain ingestion component of running the stats dashboard. This does not include
grafana, or the dashboard itself.

## Deployments

### Basic

The only required values for the deployment are the influx information such as username, password, host, and
database, as well as the lotus api info. No jwt token information is required.

See the `values.yaml` for how to name the secret and the required values.

```
helm upgrade --install lotus-stats ./lotus-stats --set lotusApiInfo=/dns/fullnode-0-lotus-daemon.default.svc.cluster.local/tcp/1234
```
_using a `lotus-fullnode` deployment named `fullnode-0`_
