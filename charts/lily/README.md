# Lily Helm chart

This helm chart deploys the Lily daemon on Kubernetes.


## Notes on Migrating from Visor chart v5.0.1 to Lily v0.1

- Please review the new defaults to ensure they are compatible with your prior installation. Values can be retrieved with `helm get values <repo_name>/lily`.

## Installing

With many configuration items which may need adjusting, it is recommended to manage releases using a `values.yaml`. For example:

```
helm install --name my-visor-release-name -f value.yaml .
```
## Configuration

