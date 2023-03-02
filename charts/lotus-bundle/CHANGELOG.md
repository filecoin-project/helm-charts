# Changelog

## 0.0.22

### Fixed

* Added error detection in the snapshot-importer initContainer so that
  the failed snapshot import don't update the `date_initialized` bookmark
