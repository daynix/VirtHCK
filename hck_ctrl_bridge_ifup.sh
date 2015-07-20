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

. `dirname $0`/hck_setup.cfg

enslave_iface ${CTRL_BR_NAME} $1
