# Volume Snapshotter

The volume snapshotter chart provides a cronjob to rotate through volumesnapshots of pvc resources.

## Deployments

### Basic

The basic install will run a snapshot every 24 hours at midnight utc, with a desired count of 3 snapshots.

```
helm upgrade --install snapshotter-pvc-name ./volume-snapshotter --set pvc=name-of-pvc
```
