#!/bin/bash

function usage {
  echo "$(basename $0) usage: "
  echo "    -w warning_level Example: 80"
  echo "    -c critical_level Example: 90"
  echo ""
  exit 1
}

while [[ $# -gt 1 ]]
do
    key="$1"
    case $key in
      -w)
      WARN="$2"
      shift
      ;;
      -c)
      CRIT="$2"
      shift
      ;;
      *)
      usage
      shift
      ;;
  esac
  shift
done

[ ! -z ${WARN} ] && [ ! -z ${CRIT} ] || usage

CONTAINERS=$(docker ps -a | grep -v CONTAINER | grep "Up " | wc -l)

if [[ ${CONTAINERS} -gt ${CRIT} ]]
then
  echo "CRITICAL - ${CONTAINERS} containers running |CONTAINERS=${CONTAINERS};;;;"
  exit 2
elif [[ ${CONTAINERS} -gt ${WARN} ]]
then
  echo "WARNING - ${CONTAINERS} containers running |CONTAINERS=${CONTAINERS};;;;"
  exit 1
else
  echo "OK - ${CONTAINERS} containers running |CONTAINERS=${CONTAINERS};;;;"
  exit 0
fi
