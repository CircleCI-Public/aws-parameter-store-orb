#!/usr/bin/env bash

ORB_EVAL_FILTER=$(eval echo "${ORB_EVAL_FILTER}")

mkdir -p /tmp/parameterstore/
for row in $(aws ssm describe-parameters --no-paginate --parameter-filters "${ORB_EVAL_FILTER}" | jq -c '.Parameters[]'); do
  _jq() {
    PARNAME=$(jq -r '.Name' <<< "${row}")
    PARDATA=$(aws ssm get-parameters --with-decryption --names "${PARNAME}" | jq '.Parameters[].Value')
    if [ -z "$PARDATA" ]
    then
      echo "${PARNAME} appears to be empty. Please double check the value of this parameter."
      exit 1
    fi
    if [ -f /tmp/parameterstore/"${PARNAME}" ]
    then
      echo "This value has already been stored. Is this value stored twice?"
      exit 1
    fi
    echo "${PARDATA}" >> /tmp/parameterstore/"${PARNAME}"
    echo "export ${PARNAME}=$(cat /tmp/parameterstore/"${PARNAME}")" >> /tmp/parameterstore/PARAMETERSTORESOURCEFILE
  }
  _jq
done

# shellcheck source=/dev/null
source /tmp/parameterstore/PARAMETERSTORESOURCEFILE
