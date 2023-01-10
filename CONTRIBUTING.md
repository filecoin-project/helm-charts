# Contributing Guidelines
Contributions are welcome via GitHub Pull Requests. This document outlines the process to help get your contribution accepted.

### Technical Requirements
When submitting a PR make sure that it:
- Must pass CI jobs for linting
- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles. This is the version that is going to be merged in the GitHub repository, then our CI/CD system is going to publish in the Helm registry a new patch version including your changes and the latest images and dependencies.
