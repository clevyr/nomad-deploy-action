#!/bin/sh
JOB_NAME=$(sudo head -1 "$GITHUB_WORKSPACE/$NOMAD_JOB" | grep job | cut -d ' ' -f 2 | cut -d '"' -f 2)

set -euxo pipefail

readonly PUBLIC_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

_changeSecurityGroupRule() {
    aws \
        --region "${AWS_REGION:-us-east-2}" \
        ec2 "$1-security-group-ingress" \
        --group-id "$AWS_SECURITY_GROUP" \
        --protocol tcp \
        --cidr "$PUBLIC_IP/32" \
        --port "${NOMAD_PORT:-4646}"
}

if [ -n "${AWS_SECURITY_GROUP:-}" ]; then
    _changeSecurityGroupRule authorize
    trap "_changeSecurityGroupRule revoke" INT TERM EXIT
fi

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
sudo apt-get update && sudo apt-get install nomad
sudo apt-get install jq
sed -i "s/\[\[\.version\]\]/$DOCKER_TAG/" "$GITHUB_WORKSPACE/$NOMAD_JOB"
sudo head -1 "$GITHUB_WORKSPACE/$NOMAD_JOB" | grep job | cut -d ' ' -f 2
DEPLOY_CNC="${DEPLOY_CNC:-false}"
ENV_HAS_CNC="${ENV_HAS_CNC:-false}"
# If the env has CNC and we don't want to deploy it - we need to modify the job file to use the existing tag
if [ "$DEPLOY_CNC" = "false" ] && [ "$ENV_HAS_CNC" = "true" ]; then
    CNC_LATEST_IMAGE=$(nomad job inspect $JOB_NAME | jq '.[].TaskGroups[].Tasks[].Config.image' | grep cnc | rev | cut -d ':' -f 1 | rev | cut -d '"' -f 1)
    sed -i "s/\[\[\.version-cnc\]\]/$CNC_LATEST_IMAGE/" "$GITHUB_WORKSPACE/$NOMAD_JOB"
    echo "deployed cnc with same tag as existing"
    echo $CNC_LATEST_IMAGE
else
    sed -i "s/\[\[\.version-cnc\]\]/$DOCKER_TAG/" "$GITHUB_WORKSPACE/$NOMAD_JOB"
    echo "deployed cnc with new tag"
fi


nomad job run "$GITHUB_WORKSPACE/$NOMAD_JOB"
