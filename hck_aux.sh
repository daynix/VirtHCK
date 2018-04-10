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

# Setup functions file

# 4-digit unique ID
UNIQUE_ID=`printf "%04d" ${UNIQUE_ID}`
UID_FIRST=`printf $UNIQUE_ID | cut -c1,2`
UID_SECOND=`printf $UNIQUE_ID | cut -c3,4`

#VNC ports
PORT_BASE=`expr ${UNIQUE_ID} '*' 3`
STUDIO_PORT=`expr ${PORT_BASE} - 2`
CLIENT1_PORT=`expr ${PORT_BASE} - 1`
CLIENT2_PORT=`expr ${PORT_BASE}`

# Aux. bridges
CTRL_BR_NAME=ctrltestbr_${UNIQUE_ID}
TEST_BR_NAME=hcktestbr_${UNIQUE_ID}

timestamp()
{
    echo `date -u +'%Y-%m-%dT%H-%M-%SZ'`
}

STUDIO_IMAGE=`readlink -f $STUDIO_IMAGE`
CLIENT1_IMAGE=`readlink -f $CLIENT1_IMAGE`
CLIENT2_IMAGE=`readlink -f $CLIENT2_IMAGE`

test x"${SNAPSHOT}" = xon && SNAPSHOT_OPTION="-snapshot"
test x"${UNSAFE_CACHE}" = xon && DRIVE_CACHE_OPTION=",cache=unsafe"
test x"${ENLIGHTENMENTS_STATE}" = xon && ENLIGHTENMENTS_OPTION=,hv_spinlocks=0x1FFF,hv_relaxed
test x"${CLIENT_WORLD_ACCESS}" = xon && CLIENT_WORLD_ACCESS_NOTIFY="ENABLED!!!" || CLIENT_WORLD_ACCESS_NOTIFY="disabled"

if [ z${ENABLE_S3} =  zon ]
then
S3_DISABLE_OPTION="0"
else
S3_DISABLE_OPTION="1"
fi

if [ z${ENABLE_S4} =  zon ]
then
S4_DISABLE_OPTION="0"
else
S4_DISABLE_OPTION="1"
fi

STUDIO_TELNET_PORT=$(( ${STUDIO_PORT} + 10000 ))
CLIENT1_TELNET_PORT=$(( ${CLIENT1_PORT} + 10000 ))
CLIENT2_TELNET_PORT=$(( ${CLIENT2_PORT} + 10000 ))

MONITOR_STUDIO="-monitor telnet::${STUDIO_TELNET_PORT},server,nowait -monitor vc"
MONITOR_CLIENT1="-monitor telnet::${CLIENT1_TELNET_PORT},server,nowait"
MONITOR_CLIENT2="-monitor telnet::${CLIENT2_TELNET_PORT},server,nowait"

if [ z${VIDEO_TYPE} =  zVNC ]
then
    GRAPHICS_STUDIO="-vnc :${STUDIO_PORT}"

    GRAPHICS_CLIENT1="-vga cirrus -vnc :${CLIENT1_PORT}"
    CLIENT1_PORTS_MSG="Vnc ${CLIENT1_PORT}/$(( ${CLIENT1_PORT} + 5900 )) Telnet ${CLIENT1_TELNET_PORT}"

    GRAPHICS_CLIENT2="-vga cirrus -vnc :${CLIENT2_PORT}"
    CLIENT2_PORTS_MSG="Vnc ${CLIENT2_PORT}/$(( ${CLIENT2_PORT} + 5900 )) Telnet ${CLIENT2_TELNET_PORT}"

    MONITOR_STDIO="${MONITOR_STDIO} -monitor vc"
    MONITOR_CLIENT1="${MONITOR_CLIENT1} -monitor vc"
    MONITOR_CLIENT2="${MONITOR_CLIENT2} -monitor vc"
fi

if [ z${VIDEO_TYPE} =  zSPICE ]
then
   GRAPHICS_STUDIO="-vnc :${STUDIO_PORT}"

   CLIENT1_SPICE_PORT=$(( ${CLIENT1_PORT} + 5900 ))
   CLIENT2_SPICE_PORT=$(( ${CLIENT2_PORT} + 5900 ))


   GRAPHICS_CLIENT1="-spice port=${CLIENT1_SPICE_PORT},disable-ticketing -vga qxl -global qxl-vga.revision=3"
   CLIENT1_PORTS_MSG="Spice ${CLIENT1_SPICE_PORT} Telnet ${CLIENT1_TELNET_PORT}"

   GRAPHICS_CLIENT2="-spice port=${CLIENT2_SPICE_PORT},disable-ticketing -vga qxl -global qxl-vga.revision=3"
   CLIENT2_PORTS_MSG="Spice ${CLIENT2_SPICE_PORT} Telnet ${CLIENT2_TELNET_PORT}"
fi

if [ ! -z  "${CLIENT1_N_QUEUES}" ]
then
    CLIENT1_N_VECTORS=$(( ${CLIENT1_N_QUEUES} * 2 + 2))
    CLIENT1_NETDEV_QUEUES=${CLIENT1_N_QUEUES}
    CLIENT1_MQ_DEVICE_PARAM=",mq=on,vectors=${CLIENT1_N_VECTORS}"
fi

if [ ! -z  "${CLIENT2_N_QUEUES}" ]
then
    CLIENT2_N_VECTORS=$(( ${CLIENT2_N_QUEUES} * 2 + 2))
    CLIENT2_NETDEV_QUEUES=${CLIENT2_N_QUEUES}
    CLIENT2_MQ_DEVICE_PARAM=",mq=on,vectors=${CLIENT2_N_VECTORS}"
fi

#SMB share on host
if [ -d "$SHARE_ON_HOST" ] && [ "$SHARE_ON_HOST" != "false" ]
then
   SHARE_ON_HOST=`cd ${SHARE_ON_HOST} && pwd`  # Get the absolute path
elif [ "$SHARE_ON_HOST" != "false" ]
then
   echo "Directory ${SHARE_ON_HOST} does not exist!"
   echo "Either create it, or set the \"SHARE_ON_HOST\" variable to \"false\"."
   echo "Running without a share..."
   SHARE_ON_HOST="false"
fi

remove_bridges() {
  case $TEST_NET_TYPE in
  bridge)
     ifconfig ${TEST_BR_NAME} down
     brctl delbr ${TEST_BR_NAME}
     ;;
  OVS)
     ovs-vsctl del-br ${TEST_BR_NAME}
     ;;
  esac

 ifconfig ${CTRL_BR_NAME} down
 brctl delbr ${CTRL_BR_NAME}
}

queue_len_tx()
{
    case $1 in
        ''|*[!0-9]*) p1=1 ;;
        *) p1=$1 ;;
    esac

    case $2 in
        ''|*[!0-9]*) p2=1 ;;
        *) p2=$2 ;;
    esac

    echo $(( ( $p1 > $p2 ? $p1 : $p2 ) * 2048 ))
}

create_bridges() {
  case $TEST_NET_TYPE in
  bridge)
     brctl addbr ${TEST_BR_NAME} 2>&1 | grep -v "already exists"
     ifconfig ${TEST_BR_NAME} up
     ifconfig ${TEST_BR_NAME} txqueuelen $(queue_len_tx $CLIENT1_N_QUEUES $CLIENT2_N_QUEUES)
     ;;
  OVS)
     ovs-vsctl add-br ${TEST_BR_NAME}
     ;;
  esac

 brctl addbr ${CTRL_BR_NAME} 2>&1 | grep -v "already exists"
 ifconfig ${CTRL_BR_NAME} up
}

enslave_iface() {
BRNAME=$1
IFNAME=$2

ifconfig ${IFNAME} promisc 0.0.0.0 &&
brctl addif ${BRNAME} ${IFNAME} &&
ethtool -K ${IFNAME} tx off
}

enslave_test_iface() {
  BRNAME=$1
  IFNAME=$2

  ifconfig ${IFNAME} promisc 0.0.0.0 &&

  case $TEST_NET_TYPE in
  bridge)
     brctl addif ${BRNAME} ${IFNAME} ||
     echo ERROR: Failed to enslave ${IFNAME} to ${BRNAME} bridge
     ;;
  OVS)
     { ovs-vsctl add-port ${BRNAME} ${IFNAME} &&
     ovs-vsctl set port ${IFNAME} other-config:priority-tags=true; } ||
     echo ERROR: Failed to enslave ${IFNAME} to ${BRNAME} ovs-bridge
     ;;
  esac

  ethtool -K ${IFNAME} tx off
  ifconfig ${IFNAME} txqueuelen $(queue_len_tx $CLIENT1_N_QUEUES $CLIENT1_N_QUEUES)
}

enslave_test_iface_macvtap() {
  BRNAME=$1
  UNIQUE_SUFFIX=$2
  MAC_ADDRESS=$3

  ip link add link ${BRNAME} macvtap-${UNIQUE_SUFFIX} address ${MAC_ADDRESS} type macvtap mode bridge ||
  echo ERROR: Failed to create macvtap interface
  ifconfig macvtap-${UNIQUE_SUFFIX} up ||
  echo ERROR: Failed to bring up macvtap-${UNIQUE_SUFFIX} interface
  TAP_ID=`ip link show macvtap-${UNIQUE_SUFFIX} | grep macvtap-${UNIQUE_SUFFIX}  | cut -f1 -d':'`
  echo "/dev/tap${TAP_ID}"
}

delete_macvtap() {
  ip link del macvtap-$1
}

dump_config()
{
    if [ ! -z  "${TEST_DEV_EXTRA_PARAMS}" ]
    then
        local EXTRA_PARAMS="${TEST_DEV_EXTRA_PARAMS}"
    else
        local EXTRA_PARAMS=None
    fi

cat <<END
Setup configuration
  Machine type................${MACHINE_TYPE}
  Setup ID................... ${UNIQUE_ID}
  Test suite type............ ${TEST_DEV_TYPE}
  Test device................ ${TEST_DEV_NAME}
  Test device extra config... ${EXTRA_PARAMS}
  Graphics................... ${VIDEO_TYPE}
  Test network backend....... ${TEST_NET_TYPE}
  Studio VM display port..... Vnc ${STUDIO_PORT}/$(( ${STUDIO_PORT} + 5900 )) Telnet ${STUDIO_TELNET_PORT}
  Client 1 display port...... ${CLIENT1_PORTS_MSG}
  Client 2 display port...... ${CLIENT2_PORTS_MSG}
  QEMU binary................ ${QEMU_BIN}
  Studio VM image............ ${STUDIO_IMAGE}
  Client 1 VM Image.......... ${CLIENT1_IMAGE}
  Client 2 VM Image.......... ${CLIENT2_IMAGE}
  SMB share on host.......... ${SHARE_ON_HOST}
  Client world access........ ${CLIENT_WORLD_ACCESS_NOTIFY}
  Client 1 VCPUs............. ${CLIENT1_CPUS}
  Client 2 VCPUs............. ${CLIENT2_CPUS}
  Memory for each client..... ${CLIENT_MEMORY}
  World network device....... ${WORLD_NET_DEVICE}
  Control network device..... ${CTRL_NET_DEVICE}
  VHOST...................... ${VHOST_STATE}
  Enlightenments..............${ENLIGHTENMENTS_STATE}
  S3 enabled..................${ENABLE_S3}
  S4 enabled..................${ENABLE_S4}
  Snapshot mode.............. ${SNAPSHOT}
END
}

LOOPRUN_FILE=${HCK_ROOT}"/.hck_stop_looped_vms_${UNIQUE_ID}.flag"

loop_run_vm() {
  while true; do
    $*
    test -f $LOOPRUN_FILE && return 0
    sleep 2
  done
}

loop_run_stop() {
  touch $LOOPRUN_FILE
}

loop_run_reset() {
  rm -f $LOOPRUN_FILE
}

remove_bridge_scripts() {
  for p in 'ctrl' 'world' 'test'; do
    rm -f ${HCK_ROOT}"/hck_${p}_bridge_ifup_${UNIQUE_ID}.sh"
  done
}

IVSHMEM_SOCKET=/tmp/ivshmem_socket_${UNIQUE_ID}
IVSHMEM_PID=/var/run/ivshmem-server_${UNIQUE_ID}.pid

run_ivshmem_server() {
  if [ "${TEST_DEV_TYPE}" = "ivshmem" ]; then
    echo Running ivshmem server...
    sudo rm -f /tmp/ivshmem_socket_${UNIQUE_ID}
    ${IVSHMEM_SERVER_BIN} -p ${IVSHMEM_PID}  -S ${IVSHMEM_SOCKET}
  fi
}

kill_ivshmem_server() {
  if [ "${TEST_DEV_TYPE}" = "ivshmem" ]; then
    echo stopping ivshmem server...
    sudo kill ${cat ${IVSHMEM_PID}}
  fi
}
