#!/bin/bash

_SCRIPT="$(docker inspect --format='{{index .Config.Labels "docker-events-handler.'${_status}'"}}' ${_name})"

if [ ! -z "${_SCRIPT}" ]; then
  if [ -x "$(dirname $0)/${_SCRIPT}" ]; then
    printf "Launching $(dirname $0)/${_SCRIPT}\n"
    "$(dirname $0)/${_SCRIPT}"
  else
    printf "WARN: Script $(dirname $0)/${_SCRIPT} does not exist\n"
  fi
fi
