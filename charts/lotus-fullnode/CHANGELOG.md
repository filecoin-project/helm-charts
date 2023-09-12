# Changelog
## 0.4.4-rc1
* Support aria2c snapshot downloads.
  Note: Enabling this updates the security context of the snapshot-downloader container to run
  as root, so that it can install aria2c at runtime

## 0.4.3
* Set all storageclasses to be optional with no default in values.yaml so they
  use the cluster's default storageclass
