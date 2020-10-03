#!/bin/bash
set -e

for chart in $(ls charts); do
    helm lint "charts/${chart}"
done
