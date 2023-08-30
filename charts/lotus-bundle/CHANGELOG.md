# Changelog

## 0.1.5
* Fix errors in last release
  - Don't enable FEVM by default
  - Fix erroneous configmap name override in default values
  - Remove inappropriate splitstore defaults

## 0.1.4 - Erroneous release, please skip to 0.1.5+
* Added the ability to inject lotus.config.content to the lotus container's
  /var/lib/lotus/config.toml file, allowing the config file to be overwritten.
  This is it mitigate a
  (bug)[https://github.com/filecoin-project/lotus/issues/11198] introduced in
  lotus 1.23.3.

## 0.1.3-rc4
* Added podManagementPolicy support

## 0.1.3-rc2
* Added resource constraints for lotus container

## 0.1.3-rc1
* Support setting snapshot URL

## 0.1.3-rc0
* Support arbitrary extra volumes/volumeMounts for the lotus container

## 0.1.2
* Added missing values.yaml updates from the previous change
* Added validation function to ensure required env vars are set when
  `lotus.lite.enabled` is `true`

## 0.1.2
* Added missing values.yaml updates from the previous change
* Added validation function to ensure required env vars are set when
  `lotus.lite.enabled` is `true`

## 0.1.1
* Replaced the lotus containers switch-based env vars in favor of supplying
  the env vars directly in values in a map, and making use of a template
  function to populate the the container env map nicely, i.e.
  values.yaml:
  ```
  lotus:
    env:
      FOO: bar
  ```
  Becomes
  ```
  spec.template.spec.containers[<lotus-index>].env:
  - name: FOO
    value: bar
  ```

  While also supporting valueFrom et al.

## 0.0.22

### Fixed

* Added error detection in the snapshot-importer initContainer so that
  the failed snapshot import don't update the `date_initialized` bookmark
