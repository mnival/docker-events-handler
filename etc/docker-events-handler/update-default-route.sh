#!/bin/bash
#set -x -v

_CONTAINER_NAME="${_name}"
_PREFIX_NSENTER="nsenter -n -t $(docker inspect --format {{.State.Pid}} ${_CONTAINER_NAME})"
_CONF="$(docker inspect --format='{{index .Config.Labels "conf.handler"}}' ${_CONTAINER_NAME})"

for i in $(printf "${_CONF}" | awk 'BEGIN{FS=";"; RS=" "} {if ($1 ~ "^default" && $2 ~ "^4|^6") {printf "%s;%s\n",$2,$3}}' | sort -u); do
	_IPV="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $1}')"
	_IP_DEFAULT="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $2}')"
  printf "Remove default route for ipv${_IPV}\n"
	${_PREFIX_NSENTER} ip -${_IPV} route del default
  printf "Add default route for ipv${_IPV}\n"
	${_PREFIX_NSENTER} ip -${_IPV} route add default via ${_IP_DEFAULT} dev eth0
done

for i in $(printf "${_CONF}" | awk 'BEGIN{FS=";"; RS=" "} {if ($1 ~ "^del" && $2 ~ "^4|^6") {printf "%s;%s\n",$2,$3}}' | sort -u); do
  _IPV="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $1}')"
  _SUBNET="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $2}')"
  printf "Remove ${_SUBNET} route for ipv${_IPV}\n"
  ${_PREFIX_NSENTER} ip -${_IPV} route del ${_SUBNET}
done
