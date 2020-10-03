#!/bin/bash
BRANCH=repo
mkdir -p .releases

for chart in $(ls charts); do
    helm package "charts/${chart}" --destination .releases/
done

git checkout "${BRANCH}"

helm repo index .releases/ --merge ./index.yaml --url https://filecoin-project.github.io/helm-charts

cr upload --git-repo "${CIRCLE_PROJECT_USERNAME}" --owner "${CIRCLE_PROJECT_REPONAME}" -p .releases/ --token "${GITHUB_TOKEN}"
cr index --charts-repo https://filecoin-project.github.io/helm-charts --git-repo "${CIRCLE_PROJECT_USERNAME}" --owner "${CIRCLE_PROJECT_REPONAME}" -p releases/ --token "${GITHUB_TOKEN}" --index-path index.yaml

git config user.email "${GITHUB_EMAIL}"
git config user.name "${GITHUB_USERNAME}"
git add index.html
git commit -m "update helm chart repo index to ${CIRCLE_SHA1}"
git push https://${GITHUB_TOKEN}@github.com/filecoin-project/helm-charts.git "${BRANCH}"
