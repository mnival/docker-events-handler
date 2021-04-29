#!/bin/bash

_CONTAINER_NAME="${_name}"
_PREFIX_NSENTER="nsenter -n -t $(docker inspect --format {{.State.Pid}} ${_CONTAINER_NAME})"
_CONF="$(docker inspect --format='{{index .Config.Labels "conf.handler"}}' ${_CONTAINER_NAME})"

for i in $(printf "${_CONF}" | awk 'BEGIN{FS=";"; RS=" "} {if ($1 ~ "^4|^6") {printf "%s;%s\n",$1,$4}}' | sort -u); do
	_IP_ROUTE="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {if ($1 ~ "^4") {printf "0.0.0.0/0"} else {printf "::/0"}}')"
	_IPV="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $1}')"
	_PORT="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $2}')"
	printf "Add rule and route for port ${_PORT} for ip version ${_IPV} on ${_CONTAINER_NAME}\n"
	${_PREFIX_NSENTER} ip -${_IPV} rule add fwmark ${_PORT} lookup ${_PORT}
	${_PREFIX_NSENTER} ip -${_IPV} route add local ${_IP_ROUTE} dev lo table ${_PORT}
done

for i in $(printf "${_CONF}" | awk 'BEGIN{FS=";"; RS=" "} {if ($1 ~ "^4|^6") {printf "%s\n",$0}}' | sort -u); do
	_IPTABLE="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {if ($1 ~ "^4") {printf "iptables"} else {printf "ip6tables"}}')"
	_IPV="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $1}')"
	_PROTO="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {printf "%s",$2}')"
	_SRC_IP="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {printf "%s",$3}')"
	_SRC_PORT="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {printf "%s",$4}')"
	printf "Add rule iptable for port ${_SRC_PORT} protocol ${_PROTO} for ip version ${_IPV} on ${_CONTAINER_NAME}\n"
	${_PREFIX_NSENTER} ${_IPTABLE} -t mangle -A PREROUTING -p ${_PROTO} -s ${_SRC_IP} --sport ${_SRC_PORT} -j MARK --set-xmark ${_SRC_PORT}
done

for i in $(printf "${_CONF}" | awk 'BEGIN{FS=";"; RS=" "} {if ($1 ~ "^4|^6") {printf "%s;%s\n",$1,$3}}' | sort -u); do
	_IPTABLE="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {if ($1 ~ "^4") {printf "iptables"} else {printf "ip6tables"}}')"
	_IPV="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {print $1}')"
	_DEST_IP="$(printf -- "${i}" | awk 'BEGIN{FS=";"} {printf "%s",$2}')"
	printf "Add rule ${_IPTABLE} for POSTROUTING on ${_CONTAINER_NAME}\n"
	${_PREFIX_NSENTER} ${_IPTABLE} -t nat -A POSTROUTING -o eth0 -d ${_DEST_IP} -j RETURN
done

${_PREFIX_NSENTER} iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
${_PREFIX_NSENTER} ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
