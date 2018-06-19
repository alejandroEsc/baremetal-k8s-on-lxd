#Troubleshooting

## LXD/LXC issues

### lxd remote add error
When on a staging node, you may want to add a remote host. However, when doing so you may find the following error
```
Error: Certificate already in trust store
```

To fix this, you may go to that node, and run 
```
lxc config trust list
```

where you may find

```
+--------------+--------------------------+------------------------------+------------------------------+
| FINGERPRINT  |       COMMON NAME        |          ISSUE DATE          |         EXPIRY DATE          |
+--------------+--------------------------+------------------------------+------------------------------+
| bd9ed94f50e1 | ubuntu@maas-controller-2 | May 16, 2018 at 4:20pm (UTC) | May 13, 2028 at 4:20pm (UTC) |
+--------------+--------------------------+------------------------------+------------------------------+
| ee78s74860d8 | root@nuc2-1              | May 23, 2018 at 3:21pm (UTC) | May 20, 2028 at 3:21pm (UTC) |
+--------------+--------------------------+------------------------------+------------------------------+
```

Note that the staging noce is `ubuntu@maas-controller-2` and we see here that an entry already exists.
Simply run 

```
lxc config trust remove <fingerprint>
```
in the case above, the fingerprint would be `bd9ed94f50e1`. You can then try once again to add the remote host
and it should work.

### Cannot contact any lxc/lxd server in the cluster 
Several issues can cause this problem, we will try to organize the issues as we come upon them. The most common
symptom is

```
lxc list
Error: Get http://unix.socket/1.0: dial unix /var/snap/lxd/common/lxd/unix.socket: connect: no such file or directory
```

We recommend that you run the follow list of commands to determine the actual cause

```
sudo systemctl status snap.lxd.daemon
```

```
journalctl -u snap.lxd.daemon
```

We now review a few example cases of issues.

#### Error: failed to open cluster database: failed to ensure schema: failed to begin transaction: cannot start a transaction within a transaction
For this error none of the nodes in the cluster would come up, each would mention the above issue. The
resolution was to perform the following in each node:

```
sudo systemctl stop lxd lxd.socket
sudo pkill lxd
sudo lxd --debug --group lxd
```

This essentially restarts lxd on each of the nodes, and allows them to make contact with each other and start processing. The
last line in particularly was important. Once the nodes are talking to each other, then turn off each of
the processes in the following order

```
ctrl-c
sudo systemctl restart snap.lxd.daemon
```
Do so one at a time on each machine. LXD will now be running. Its unclear what exactly got us to this
state but it did.

## helm issues


## etcd issues

### New etcd-cluster created, flannel missing key
So you somehow killed all etcd instances, but managed to deploy a new one, essentially creating a new
k8s cluster. Flannel complaints that its missing etcd key for networking, run the following to fix: 
```
etcd.etcdctl mk /coreos.com/network/config '{"Network":"10.1.0.0/16"}'
```
where you should choose a network that doesnt interfere with either docker, or your existing subnet.

### Upon Reboot, etcd will not start because 'permission denied'
The error can be viewed by looking at the logs
```
journalctl -u snap.etcd.etcd
...
Jun 07 05:03:07 nuc2-2-ubuntu-2CPU-8GB-1 etcd[1267]: cannot access data directory: mkdir /var/snap/etcd/current: permission denied
Jun 07 05:03:07 nuc2-2-ubuntu-2CPU-8GB-1 systemd[1]: snap.etcd.etcd.service: Main process exited, code=exited, status=1/FAILURE
Jun 07 05:03:07 nuc2-2-ubuntu-2CPU-8GB-1 systemd[1]: snap.etcd.etcd.service: Unit entered failed state.
Jun 07 05:03:07 nuc2-2-ubuntu-2CPU-8GB-1 systemd[1]: snap.etcd.etcd.service: Failed with result 'exit-code'.
...
```
if you investigate the directory structure you will see that group and user accounts are correct. Check the snap interfaces

```
snap interfaces | grep etcd
  :home                      cdk-addons,etcd,kube-apiserver,kube-controller-manager,kube-scheduler
  :network-bind              etcd,kube-apiserver,kube-controller-manager,kube-scheduler
  -                          etcd:removable-media
```
the problem is the last line, it essentialy etcd is not plugged in and so has no access to memory

```
sudo snap connect etcd:removable-media core:removable-media
```

should now connect and have access to memory, restart the service
```
sudo systemctl restart snap.etcd.etcd.service 
```
and we should be back.

### Upon reboot, etcd will not start up due to: snap-update-ns failed with code 1
The full error looks like

```
cannot change profile for the next exec call: No such file or directory
snap-update-ns failed with code 1
```
whenever you try to run etcd

```
Jun  8 18:54:07 nuc2-2-ubuntu-2cpu-8gb-1 kernel: [  681.751079] audit: type=1400 audit(1528484047.174:778): apparmor="DENIED" operation="change_onexec" info="label not found" error=-2 profile="/usr/lib/snapd/snap-confine" name="snap-update-ns.etcd" pid=20827 comm="snap-confine"
Jun  8 18:54:09 nuc2-2-ubuntu-2cpu-8gb-1 kernel: [  683.598811] audit: type=1400 audit(1528484049.022:779): apparmor="DENIED" operation="change_onexec" info="label not found" error=-2 profile="/usr/lib/snapd/snap-confine" name="snap-update-ns.etcd" pid=21000 comm="snap-confine"
```

The issues is actually app-armor and profiles



```
sudo apparmor_parser /var/lib/snapd/apparmor/profiles/*
```


