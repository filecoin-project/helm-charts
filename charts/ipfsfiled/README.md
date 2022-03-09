# ipfsfiled Helm chart

This helm chart deploys [ipfsfiled](https://github.com/iand/ipfsfiled) on Kubernetes.

## Installing

With many configuration items which may need adjusting, it is recommended to manage releases using a `values.yaml`. For example:

```
helm install --name my-release-name -f value.yaml .
```

