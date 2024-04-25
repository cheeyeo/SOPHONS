#!/bin/bash

# Just-in-time Self-hosted runner script to run on remote EC2 host
# Inputs:
# GITHUB_REPOSITORY
# GITHUB_OWNER
# GITHUB_PERSONAL_TOKEN
# NAME
# LABELS

LABELS=()
NAME=""

while getopts ":l:n:" opt; do
    case $opt in
        l )
          LABELS+=("${OPTARG}")
          ;;
        n )
          NAME="${OPTARG}"
          ;; 
        ? ) 
          echo "Invalid option: -${OPTARG}"
          exit 1
          ;;
    esac
done

shift $((OPTIND-1))

echo ${LABELS[@]}
echo $NAME


echo "[INFO] Installing runner agent..."

RUNNER_VERSION="2.315.0"
ARCH="x64"

mkdir -p /tmp/actions-runner && cd /tmp/actions-runner

curl -Ls -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh


if [ -n "${GITHUB_REPOSITORY}" ]; then
  jit_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/generate-jitconfig"
else
  jit_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/generate-jitconfig"
fi

json_payload=$(jq -c -n '{"name": $runner_name, "runner_group_id":1, labels: ($runner_labels | split(" "))}' --arg runner_name "$NAME" --arg runner_labels "${LABELS[*]}")
echo $json_payload

resp=$(curl -sX POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_PERSONAL_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28" "${jit_url}" -d $json_payload)
echo "[INFO] GITHUB RESP: ${resp}"

encoded_jit_config=$(echo "${resp}" | jq .encoded_jit_config --raw-output)

./run.sh --jitconfig ${encoded_jit_config}