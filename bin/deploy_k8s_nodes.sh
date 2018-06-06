#!/bin/bash

machine=$1
action=$2
pub_key_file=$3
script_file=$4
storage=$5

function delete_container(){
	machine=$1
	container_name=$2
	limit_cpu=$3
	limit_memory=$4

	echo
	echo "deleting ${machine}:${machine}-${container_name}..."
	lxc stop  ${machine}:${machine}-${container_name}
	lxc delete --force ${machine}:${machine}-${container_name}
	echo "...done"
}

function create_container(){
	machine=$1
	container_name=$2
	limit_cpu=$3
	limit_memory=$4

	# create and start containers
	echo
	echo "launch ubuntu:16.04 --target ${machine} ${machine}:${machine}-${container_name}..."
	lxc launch ubuntu:16.04 --target ${machine} ${machine}:${machine}-${container_name}
	sleep 2

	# config changes
	echo "lxc config set ${machine}:${machine}-${container_name} limits.cpu ${limit_cpu}"
	lxc config set ${machine}:${machine}-${container_name} limits.cpu ${limit_cpu}
	echo "lxc config set ${machine}:${machine}-${container_name} limits.memory ${limit_memory}"
	lxc config set ${machine}:${machine}-${container_name} limits.memory ${limit_memory}
        echo "lxc config device add ${machine}:${machine}-${container_name} /dev/zfs unix-char path=/dev/zfs"
        lxc config device add ${machine}:${machine}-${container_name} /dev/zfs unix-char path=/dev/zfs
	sleep 2

	# lxc containter changes
	echo "lxc file push ${pub_key_file} ${machine}:${machine}-${container_name}/root/.ssh/authorized_keys"
	lxc file push ${pub_key_file} ${machine}:${machine}-${container_name}/root/.ssh/authorized_keys
	echo "lxc file push ${script_file} ${machine}:${machine}-${container_name}/root/${script_file}"
	lxc file push ${script_file} ${machine}:${machine}-${container_name}/root/${script_file}
	sleep 2
	lxc exec ${machine}:${machine}-${container_name} -- chown root:root .ssh/authorized_keys
	lxc exec ${machine}:${machine}-${container_name} -- chmod 600 .ssh/authorized_keys
	lxc exec ${machine}:${machine}-${container_name} -- bash ${script_file}
	echo "...done"

	# reboot
	echo "reboot"
	lxc exec ${machine}:${machine}-${container_name} -- sudo reboot
}

if [ "${action}" = "create" ]; then
  create_container ${machine} ubuntu-2CPU-8GB-1 2 8GB
  create_container ${machine} ubuntu-2CPU-8GB-2 2 8GB

fi

if [ "${action}" = "destroy" ]; then
  delete_container ${machine} ubuntu-2CPU-8GB-1 2 8GB
  delete_container ${machine} ubuntu-2CPU-8GB-2 2 8GB
fi

