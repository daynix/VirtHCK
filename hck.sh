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
ARGS_CFG=args.cfg

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  echo Usage:
  echo $0" [-c <CONFIG_FILE>] [st] [c1] [c2]"
  echo
  echo This script starts VirtHCK Studio with two Clients
  echo if executed without parameters, or you can specify
  echo which VMs to run with the following parameters:
  echo st - Start HCK Studio VM
  echo c1 - Start HCK Client 1 VM
  echo c2 - Start HCK Client 2 VM
  echo
  echo The default configuration file is \"hck_setup.cfg\" in the same directory
  echo that the script is run from. A different file can be specified using the
  echo \"-c\" option.
  exit
fi

if test x`whoami` != xroot
then
  echo This script must be run as superuser
  exit 1
fi

> $ARGS_CFG

while [ $# -gt 0 ]
do
key="$1"
case $key in
    -c)
    CONFIG_FILE="$2"
    shift
    ;;
    -id)
    echo UNIQUE_ID=$2 >> $ARGS_CFG
    shift
    ;;
    -device_type)
    echo TEST_DEV_TYPE=\"$2\" >> $ARGS_CFG
    shift
    ;;
    -device_name)
    echo TEST_DEV_NAME=\"$2\" >> $ARGS_CFG
    shift
    ;;
    -device_extra)
    echo TEST_DEV_EXTRA_PARAMS=\"$2\" >> $ARGS_CFG
    shift
    ;;
    -st_image)
    echo STUDIO_IMAGE=$2 >> $ARGS_CFG
    shift
    ;;
    -c1_image)
    echo CLIENT1_IMAGE=$2 >> $ARGS_CFG
    shift
    ;;
    -c1_cpus)
    echo CLIENT1_CPUS=$2 >> $ARGS_CFG
    shift
    ;;
    -c1_memory)
    echo CLIENT1_MEMORY=$2 >> $ARGS_CFG
    shift
    ;;
    -c2_image)
    echo CLIENT2_IMAGE=$2 >> $ARGS_CFG
    shift
    ;;
    -c2_cpus)
    echo CLIENT2_CPUS=$2 >> $ARGS_CFG
    shift
    ;;
    -c2_memory)
    echo CLIENT2_MEMORY=$2 >> $ARGS_CFG
    shift
    ;;
    st)
    RUN_STUDIO=true
    ;;
    c1)
    RUN_CLIENT1=true
    ;;
    c2)
    RUN_CLIENT2=true
    ;;
    ci_mode)
    CI_MODE=true
    ;;
    end)
    END=true
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
if [ -z ${CONFIG_FILE+x} ]; then
    if [ -f "${SCRIPTS_DIR}/hck_setup.cfg" ]; then
        CONFIG_FILE="${SCRIPTS_DIR}/hck_setup.cfg"
    else
        echo "A configuration file is not present or specified."
        echo "Please refer to help ($0 -h) for details."
        exit 1
    fi
elif [ ! -f "${CONFIG_FILE}" ]; then
    echo "The file ${CONFIG_FILE} does not exist."
    exit 1
fi

. ${CONFIG_FILE}

kill_jobs() {
  jobs -p > /tmp/.jobs_$$
  kill `cat /tmp/.jobs_$$ | tr '\n' ' '`
  rm -f /tmp/.jobs_$$
}

make_bridge_script() {
SCRIPTFILE="${HCK_ROOT}"/$1
REAL_ME=`logname`
cat <<EOF > ${SCRIPTFILE}
#!/bin/sh
. ${CONFIG_FILE}
$2 $3 \$1
EOF
chmod 755 ${SCRIPTFILE}
chown ${REAL_ME}:`id -g -n ${REAL_ME}` ${SCRIPTFILE}
}

make_bridge_script "hck_ctrl_bridge_ifup_${UNIQUE_ID}.sh" "enslave_iface" '${CTRL_BR_NAME}'
make_bridge_script "hck_world_bridge_ifup_${UNIQUE_ID}.sh" "enslave_iface" '${WORLD_BR_NAME}'
make_bridge_script "hck_test_bridge_ifup_${UNIQUE_ID}.sh" "enslave_test_iface" '${TEST_BR_NAME}'


trap "kill_jobs; loop_run_reset; remove_bridges; remove_bridge_scripts; exit 0" INT

if [ "$END" = true ] ; then
  remove_bridges
  remove_bridge_scripts
  kill_ivshmem_server
elif  [ "$CI_MODE" = true ] ; then
  if [ x"${RUN_STUDIO}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    echo Creating bridges...
    create_bridges
    run_ivshmem_server
    ${SCRIPTS_DIR}/run_hck_studio.sh ${CONFIG_FILE} &
  fi
  if [ x"${RUN_CLIENT1}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    ${SCRIPTS_DIR}/run_hck_client.sh ${CONFIG_FILE} 1 &
  fi
  if [ x"${RUN_CLIENT2}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    ${SCRIPTS_DIR}/run_hck_client.sh ${CONFIG_FILE} 2 &
  fi
elif [ "$END" = true ] ; then
  remove_bridges
  remove_bridge_scripts
  kill_ivshmem_server
else
  echo
  dump_config
  echo

  echo Creating bridges...
  create_bridges

  run_ivshmem_server

  loop_run_reset
  if [ x"${RUN_STUDIO}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    loop_run_vm ${SCRIPTS_DIR}/run_hck_studio.sh ${CONFIG_FILE} &
    sleep $VM_START_TIMEOUT
  fi
  if [ x"${RUN_CLIENT1}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    loop_run_vm ${SCRIPTS_DIR}/run_hck_client.sh ${CONFIG_FILE} 1 &
    sleep $VM_START_TIMEOUT
  fi
  if [ x"${RUN_CLIENT2}" = xtrue ] || [ x"${RUN_ALL}" = xtrue ]; then
    loop_run_vm ${SCRIPTS_DIR}/run_hck_client.sh ${CONFIG_FILE} 2 &
  fi
  sleep 2

  read -p "Press ENTER to disable VMs respawn..." NOT_NEEDED_VAR
  loop_run_stop
  echo VMs won\'t respawn anymore.
  wait

  sleep 2
  remove_bridges
  remove_bridge_scripts
  loop_run_reset
  kill_ivshmem_server
fi

