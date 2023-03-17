# Changelog

## 0.1.2
* Added missing values.yaml updates from the previous change

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
