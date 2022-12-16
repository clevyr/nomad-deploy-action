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
DONT_DEPLOY_CNC="${DONT_DEPLOY_CNC:-false}"
if [ "$DONT_DEPLOY_CNC" = "true" ]; then
    CNC_LATEST_IMAGE=$(nomad job inspect $JOB_NAME | jq '.[].TaskGroups[].Tasks[].Config.image' | grep cnc | rev | cut -d ':' -f 1 | rev | cut -d '"' -f 1)
    sed -i "s/\[\[\.version-cnc\]\]/$CNC_LATEST_IMAGE/" "$GITHUB_WORKSPACE/$NOMAD_JOB"
else
    sed -i "s/\[\[\.version-cnc\]\]/$DOCKER_TAG/" "$GITHUB_WORKSPACE/$NOMAD_JOB"
fi


nomad job run "$GITHUB_WORKSPACE/$NOMAD_JOB"
