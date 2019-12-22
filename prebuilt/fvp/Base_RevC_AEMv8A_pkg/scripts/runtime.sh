#!/bin/sh

export SYSTEMC_HOME="$1"/SystemC
export LD_PRELOAD="$1"/fmtplib/libstdc++.so.6
shift
exec $*
