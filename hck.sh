#!/bin/sh

# Copyright (c) 2013, Daynix Computing LTD (www.daynix.com)
# All rights reserved.
#
# Maintained by oss@daynix.com
#
# This file is a part of VirtHCK, please see the wiki page
# on https://github.com/daynix/VirtHCK/wiki for more.
#
# This code is licensed under standard 3-clause BSD license.
# See file LICENSE supplied with this package for the full license text.

VM_START_TIMEOUT=10

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  echo Usage:
  echo $0" [st] [c1] [c2]"
  echo
  echo This script starts VirtHCK Studio with two Clients
  echo if executed without parameters, or you can specify
  echo which VMs to run with the following parameters:
  echo st - Start HCK Studio VM
  echo c1 - Start HCK Client 1 VM
  echo c2 - Start HCK Client 2 VM
  exit
fi

if test x`whoami` != xroot
then
  echo This script must be run as superuser
  exit 1
fi

while [ $# -gt 0 ]
do
key="$1"
case $key in
    st)
    RUN_STUDIO=true
    ;;
    c1)
    RUN_CLIENT1=true
    ;;
    c2)
    RUN_CLIENT2=true
    ;;
    *)
    echo "Unknown option: ${key}"
    exit 1
    ;;
esac
shift
done

if [ -z ${RUN_STUDIO} ] && [ -z ${RUN_CLIENT1} ] && [ -z ${RUN_CLIENT2} ]; then
    RUN_ALL=true
fi

SCRIPTS_DIR=`dirname $0`
. ${SCRIPTS_DIR}/hck_setup.cfg

kill_jobs() {
  jobs -p > /tmp/.jobs_$$
  kill `cat /tmp/.jobs_$$ | tr '\n' ' '`
  rm -f /tmp/.jobs_$$
}

echo
dump_config
echo

trap "kill_jobs; loop_run_reset; remove_bridges; exit 0" INT

echo Creating bridges...
create_bridges

loop_run_reset
if [ x"${RUN_STUDIO}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
  loop_run_vm ${SCRIPTS_DIR}/run_hck_studio.sh &
  sleep $VM_START_TIMEOUT
fi
if [ x"${RUN_CLIENT1}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
  loop_run_vm ${SCRIPTS_DIR}/run_hck_client.sh 1 &
  sleep $VM_START_TIMEOUT
fi
if [ x"${RUN_CLIENT2}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
  loop_run_vm ${SCRIPTS_DIR}/run_hck_client.sh 2 &
fi
sleep 2

read -p "Press ENTER to disable VMs respawn..." NOT_NEEDED_VAR
loop_run_stop
echo VMs won\'t respawn anymore.
wait

sleep 2
remove_bridges
loop_run_reset
