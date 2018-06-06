#!/bin/bash
nodes=( "$@" )
echo ${nodes[@]}

for node in "${nodes[@]}"
  do
    echo " performing config changes to ${node}"
    lxc profile set ${node}:default boot.autostart "true" &> /dev/null
    lxc profile set ${node}:default linux.kernel_modules ip_tables,ip6_tables,netlink_diag,nf_nat,overlay &> /dev/null
    lxc profile set ${node}:default security.nesting "true" &> /dev/null
    lxc profile set ${node}:default security.privileged "true" &> /dev/null
    lxc profile device add ${node}:default  /dev/zfs unix-char path=/dev/zfs &> /dev/null
    echo -e 'lxc.apparmor.profile=unconfined\nlxc.mount.auto=proc:rw sys:rw\nlxc.cap.drop=' | lxc profile set ${node}:default raw.lxc -
done

