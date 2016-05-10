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

CLIENT_NUM=$1

echo "Starting HCK client #${CLIENT_NUM}"

. `dirname $0`/hck_setup.cfg

client_ctrl_ifname()
{
  echo cc${CLIENT_NUM}_${UNIQUE_ID}
}

client_test_ifname()
{
  DEVICE_NUM=$1

  echo t${DEVICE_NUM}c${CLIENT_NUM}_${UNIQUE_ID}
}

client_ctrl_mac()
{
  echo 56:cc:cc:0${CLIENT_NUM}:cc:cc
}

client_transfer_mac()
{
  echo 56:aa:aa:0${CLIENT_NUM}:aa:aa
}

client_test_mac()
{
  DEVICE_NUM=$1

  echo 56:cc:cc:0${CLIENT_NUM}:0${DEVICE_NUM}:cc
}

client_cpus()
{
  VAR_NAME=CLIENT${CLIENT_NUM}_CPUS
  eval echo \$${VAR_NAME}
}

graphics_cmd()
{
  VAR_NAME=GRAPHICS_CLIENT${CLIENT_NUM}
  eval echo \$${VAR_NAME}
}

monitor_cmd()
{
  VAR_NAME=MONITOR_CLIENT${CLIENT_NUM}
  eval echo \$${VAR_NAME}
}

usb_cmd()
{
    eval IMAGE_PATH=\$CLIENT${CLIENT_NUM}_USB_DEV
    if [ ! -z ${IMAGE_PATH} ]
    then
        echo "-device piix3-usb-uhci -drive file=${IMAGE_PATH},if=none,id=usb${CLIENT_NUM} -device usb-storage,drive=usb${CLIENT_NUM}"
    fi
}

extra_params_cmd()
{
    if [ ! -z "${TEST_DEV_EXTRA_PARAMS}" ]
    then
        echo ",${TEST_DEV_EXTRA_PARAMS}"
    fi
}

extra_cmd()
{
  VAR_NAME=CLIENT${CLIENT_NUM}_EXTRA
  eval echo \$${VAR_NAME}
}

netdev_queues_num()
{
  VAR_NAME=CLIENT${CLIENT_NUM}_NETDEV_QUEUES
  eval echo \$${VAR_NAME}
}

client_mq_device_param()
{
  VAR_NAME=CLIENT${CLIENT_NUM}_MQ_DEVICE_PARAM
  eval echo \$${VAR_NAME}
}

image_name()
{
  VAR_NAME=CLIENT${CLIENT_NUM}_IMAGE
  eval echo \$${VAR_NAME}
}

trace_file_name()
{
    VAR_NAME=CLIENT${CLIENT_NUM}_TRACE_EVENTS
    eval echo \$${VAR_NAME}
}

trace_cmd()
{
    FILE_NAME=`trace_file_name`

    if [ ! -z  "${FILE_NAME}" ]
    then
        echo "-trace events=${FILE_NAME}"
    fi
}

log_option()
{
    VAR_NAME=CLIENT${CLIENT_NUM}_LOG
    eval echo \$${VAR_NAME}
}

log_file_name()
{
    if [ z`log_option` = zon ]
    then
        mkdir -p $LOGS_DIR/client${CLIENT_NUM} > /dev/null 2>&1
        FILE_NAME=$LOGS_DIR/client${CLIENT_NUM}/`timestamp`-client${CLIENT_NUM}.log
        echo `readlink -f $FILE_NAME`
    fi
}

log_cmd()
{
    FILE_NAME=`log_file_name`

    if [ ! -z  "${FILE_NAME}" ]
    then
        echo Logging output to ${FILE_NAME} 1>&2
        echo "tee ${FILE_NAME}"
    else
        echo "cat"
    fi
}

#Machine type related difference
case $MACHINE_TYPE in
    q35 )
        BUS_NAME=pcie
        DISABLE_S3_PARAM=ICH9-LPC.disable_s3
        DISABLE_S4_PARAM=ICH9-LPC.disable_s4
        #Windows 2012R2 crashes during boot on Q35 machine with UUID set
        MACHINE_UUID=""
        ;;
    * )
        BUS_NAME=pci
        DISABLE_S3_PARAM=PIIX4_PM.disable_s3
        DISABLE_S4_PARAM=PIIX4_PM.disable_s4
        MACHINE_UUID="-uuid CDEF127c-8795-4e67-95da-8dd0a889100${CLIENT_NUM}"
        ;;
esac

TEST_IMAGE_NAME=$(dirname `image_name`)/client${CLIENT_NUM}_test_image.raw

prepare_test_image()
{
  test -f ${TEST_IMAGE_NAME} || \
  { echo Creating test image ${TEST_IMAGE_NAME}...; qemu-img create -f raw ${TEST_IMAGE_NAME} 20G; }
}

if [ x"${CLIENT_WORLD_ACCESS}" = xon ]; then
    WORLD_NET_IFACE="-netdev tap,id=hostnet9,script=${HCK_ROOT}/hck_world_bridge_ifup.sh,downscript=no,ifname=tmp_${UNIQUE_ID}_${CLIENT_NUM}
                     -device ${WORLD_NET_DEVICE},netdev=hostnet9,mac=22:11:11:11:0${CLIENT_NUM}:${UNIQUE_ID},id=tmp_${UNIQUE_ID}_${CLIENT_NUM}"
fi

IDE_STORAGE_PAIR="-drive file=`image_name`,serial=${CLIENT_NUM}110${UNIQUE_ID}${DRIVE_CACHE_OPTION}"

if [ "$IS_PHYSICAL" = "false" ]; then    # in case of a virtual device

    case $TEST_DEV_TYPE in
    network)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"

       TEST_NET_MAC_ADDRESS=`client_test_mac 1`
       TEST_DEVICE_ID=""
       case ${TEST_NETWORK_INTERFACE} in
       tap)
          TAP_DEVICE="-netdev tap,id=hostnet2,vhost=${VHOST_STATE},script=${HCK_ROOT}/hck_test_bridge_ifup.sh,downscript=no,ifname=`client_test_ifname 1`,queues=$(netdev_queues_num)"
          TEST_DEVICE_ID=",id=`client_test_ifname 1`"
          ;;
       macvtap)
          UNIQ_DESCR=$(( ${CLIENT_NUM} + ${UNIQUE_ID} ))
          TAP_ID=`enslave_test_iface_macvtap ${TEST_BR_NAME} ${UNIQ_DESCR} ${TEST_NET_MAC_ADDRESS}`
          eval "exec ${UNIQ_DESCR}<>${TAP_ID}"
          # Attention:  ifname=, script=, downscript=, vnet_hdr=, helper=, queues=, fds=, and vhostfds= are invalid with fd=
          TAP_DEVICE="-netdev tap,id=hostnet2,vhost=${VHOST_STATE},fd=${UNIQ_DESCR}"
          ;;
       * )
          echo NETWORK INTERFACE IS NOT IMPLEMENTED
          exit 1
          ;;
       esac
       TEST_NET_DEVICES="${TAP_DEVICE}
                         -device ${TEST_DEV_NAME}`extra_params_cmd`,netdev=hostnet2,mac=${TEST_NET_MAC_ADDRESS},bus=${BUS_NAME}.0$(client_mq_device_param)${TEST_DEVICE_ID}"
       ;;
    bootstorage)
       BOOT_STORAGE_PAIR="-drive file=`image_name`,if=none,id=vio_block,serial=${CLIENT_NUM}110${UNIQUE_ID}${DRIVE_CACHE_OPTION}
                          -device ${TEST_DEV_NAME}`extra_params_cmd`,bus=${BUS_NAME}.0,addr=0x5,drive=vio_block"
       ;;
    storage-blk)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_STORAGE_PAIR="-drive file=${TEST_IMAGE_NAME},if=none,id=virtio_blk,serial=${CLIENT_NUM}000${UNIQUE_ID}${DRIVE_CACHE_OPTION}
                          -device ${TEST_DEV_NAME}`extra_params_cmd`,bus=${BUS_NAME}.0,addr=0x5,drive=virtio_blk"
       prepare_test_image
       ;;
    storage-scsi)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_STORAGE_PAIR="-drive file=${TEST_IMAGE_NAME},if=none,id=virtio_scsi,serial=${CLIENT_NUM}000${UNIQUE_ID}${DRIVE_CACHE_OPTION}
                          -device ${TEST_DEV_NAME}`extra_params_cmd`,id=scsi,bus=${BUS_NAME}.0,addr=0x5
                          -device scsi-hd,drive=virtio_scsi"
       prepare_test_image
       ;;
    serial)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_SERIAL_DEVICES="-device ${TEST_DEV_NAME}`extra_params_cmd`,id=virtio_serial_pci0,addr=0x07"
       ;;
    balloon)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_BALLOON_DEVICE="-device ${TEST_DEV_NAME}`extra_params_cmd`,bus=${BUS_NAME}.0,addr=0x8"
       ;;
    rng)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_RNG_DEVICE="-device ${TEST_DEV_NAME}`extra_params_cmd`,bus=${BUS_NAME}.0,addr=0x9"
       ;;
    usb)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
       TEST_STORAGE_PAIR="
        -device usb-ehci,id=vhck_ehci
        -drive if=none,id=usbdisk,serial=${CLIENT_NUM}000${UNIQUE_ID},file=${TEST_IMAGE_NAME}
        -device ${TEST_DEV_NAME}`extra_params_cmd`,bus=vhck_ehci.0,drive=usbdisk,id=vhck_usbdisk "

        prepare_test_image
        ;;
    video)
       BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
        ;;

      * )
       echo "NOT IMPLEMENTED"
       exit 1
        ;;
    esac

else    # in case of physical device
    case $TEST_DEV_TYPE in
        network)
            BOOT_STORAGE_PAIR="${IDE_STORAGE_PAIR}"
           if [ $CLIENT_NUM -eq 1 ]; then
               TEST_NET_DEVICES="-device ${ASSIGNMENT},host=${CLIENT1_HOST_ADDRESS},$(client_mq_device_param)"
           fi
           if [ $CLIENT_NUM -eq 2 ]; then
               TEST_NET_DEVICES="-device ${ASSIGNMENT},host=${CLIENT2_HOST_ADDRESS},$(client_mq_device_param)"
           fi
        ;;

        * )
            echo "NOT IMPLEMENTED. Please note that physical device assignment is enabled."
            exit 1
        ;;
    esac
fi

if [ ${SHARE_ON_HOST} != "false" ] && [ -e "${SHARE_ON_HOST}/USE_SHARE" ]; then
  FILE_TRANSFER_SETUP="-netdev user,id=filenet0,net=${SHARE_ON_HOST_NET}.0/24,dhcpstart=${SHARE_ON_HOST_NET}.${CLIENT_NUM}00,smb=${SHARE_ON_HOST},smbserver=${SHARE_ON_HOST_NET}.1,restrict=on \
                       -device ${FILE_TRANSFER_DEVICE},netdev=filenet0,mac=`client_transfer_mac`"
fi

CTRL_NET_DEVICE="-netdev tap,id=hostnet0,script=${HCK_ROOT}/hck_ctrl_bridge_ifup.sh,downscript=no,ifname=`client_ctrl_ifname`
                 -device ${CTRL_NET_DEVICE},netdev=hostnet0,mac=`client_ctrl_mac`,bus=${BUS_NAME}.0,id=`client_ctrl_ifname`"
                 
${QEMU_BIN} \
        ${BOOT_STORAGE_PAIR} \
        ${TEST_STORAGE_PAIR} \
        ${CTRL_NET_DEVICE} \
        ${TEST_NET_DEVICES} \
        ${FILE_TRANSFER_SETUP} \
        ${TEST_SERIAL_DEVICES} \
        ${TEST_BALLOON_DEVICE} \
        ${TEST_RNG_DEVICE} \
        ${WORLD_NET_IFACE} \
        ${MACHINE_UUID} \
        -machine ${MACHINE_TYPE} \
        -m ${CLIENT_MEMORY} -smp `client_cpus`,cores=`client_cpus` -enable-kvm \
        -cpu qemu64,+x2apic,+fsgsbase,model=13${ENLIGHTENMENTS_OPTION} \
        -usbdevice tablet -boot ${BOOT_ORDER} \
        -rtc-td-hack -global kvm-pit.lost_tick_policy=discard -rtc base=localtime,clock=host,driftfix=slew \
        -global ${DISABLE_S3_PARAM}=${S3_DISABLE_OPTION} -global ${DISABLE_S4_PARAM}=${S4_DISABLE_OPTION} \
        -name HCK-Client${CLIENT_NUM}_${UNIQUE_ID}_`hostname`_${TITLE_POSTFIX} \
        `graphics_cmd` `monitor_cmd` ${SNAPSHOT_OPTION} `usb_cmd` `extra_cmd` \
        `trace_cmd` \
         2>&1 | `log_cmd`

if [ ${TEST_NETWORK_INTERFACE} = "macvtap" ]; then
  eval "exec ${UNIQ_DESCR}<>\&-"
  `delete_macvtap ${UNIQ_DESCR}`
fi
