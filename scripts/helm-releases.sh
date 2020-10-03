#!/bin/bash
BRANCH=repo
mkdir -p .releases
mkdir -p .releases-done

for chart in $(ls charts); do
    helm package "charts/${chart}" --destination .releases/
    ls .releases
    cr upload -r "${CIRCLE_PROJECT_REPONAME}" -o "${CIRCLE_PROJECT_USERNAME}" -p ".releases/" -t "${GITHUB_TOKEN}"
    mv .releases/${chart}* .releases-done/
done

mv .cr-index/index.yaml .releases/
mv .releases-done/* .releases/

git checkout -f "${BRANCH}"
mkdir .cr-index
mv .releases/index.yaml .cr-index/
cr index -c https://filecoin-project.github.io/helm-charts -r "${CIRCLE_PROJECT_REPONAME}" -o "${CIRCLE_PROJECT_USERNAME}" -p .releases/ -t "${GITHUB_TOKEN}"
mv .cr-index/index.yaml .
rm .cr-index

git config user.email "${GITHUB_EMAIL}"
git config user.name "${GITHUB_USERNAME}"
git add index.yaml
git commit -m "update helm chart repo index to ${CIRCLE_SHA1}"
git push https://${GITHUB_TOKEN}@github.com/filecoin-project/helm-charts.git "${BRANCH}"
