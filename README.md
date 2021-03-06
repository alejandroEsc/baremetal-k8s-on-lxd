# baremetal-k8s-on-lxd
Here we include tools, at first bash scripts, that can be run to help provision baremetal running an lxd cluster, to
run Kubernetes (K8s). The approach here is to deploy ubuntu 16.04 containers accross an lxd cluster with constraints,
and have them be consumed by juju as machines that can be used to run kubernetes. 

The intention here is to document what has been done to get to successfull deployment and management of a kubernetes cluster. Work
to create a cli on golang is the next objective.

# Table of Contents

- [Troubleshooting](docs/troubleshooting.md)
- [Provisioning Local Volumes](docs/provision_volumes.md)


# Getting Ready
We recommended the following setup

- One physical machine that will contain the juju controller, we will call this the staging node and will allow us to 
remotely run lxc commands as we need.
- All physical machines that you will run lxd containers, must run least lxd 3.0.0

Therefore you will have one machine that stages all changes accross your cluster. That same machine could be the maas controller
if you so wish.


To ensure, on ubuntu, that you have the latest lxd please run the following
```
sudo apt remove lxd
```

```
sudo apt remove lxd-client
```

```
sudo snap install lxd
```

The last line will install both the client `lxc` and the daemon `lxd`.

## Creating A Staging Node
To do so select a machine that you would like to stage lxc commands and deployments from. We suggest
that you use the same machine to run things such as a juju controller or a maas server, though clearly
not always the best choice for all things to be done.

When done selecting a machine make sure you go through the init process, but select NO to use clustering
```
sudo lxd init
```

when complete run the following [3]

```
lxc config set core.https_address '[::]:8443'
```

and then manually add each node

```
lxc remote add <select-a-name> <ip-address>
```


# Setting up a new LXD node.
A few tools you may want to install

- bridge utility (required if setting up a bridge)
```
sudo apt install bridge-utils -y
```

- zfs storage utilities (could you whatever storage type you want)
```
sudo apt install zfs -y
```

## Setting up a Bridge to use an existing Lan subnet
Here we assume you want to deploy in the same subnet as your physical nodes. There are pros and cons,
but here we use this method as a way to easy ssh into k8s nodes as we please.

On ubuntu 16.04 (for 18.04 netplan is the default and requires other instructions not listed here yet.) you would want to
first download the 'bridge-utils' as mentioned above. Once that is complete you will want to edit two files:

- sudo vim /etc/network/interfaces

```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

auto br0
iface br0 inet static
  bridge_ports enp0s25
  address 192.168.4.252
  netmask 255.255.255.0
  gateway 192.168.4.1
  dns-nameservers 192.168.4.2

# Source interfaces
# Please check /etc/network/interfaces.d before changing this file
# as interfaces may have been defined in /etc/network/interfaces.d
# See LP: #1262951
source /etc/network/interfaces.d/*.cfg
```
where we have added the `br0` entries which is the bridge to be consumed by the lxd containers.

- sudo vim /etc/network/interfaces.d/50-cloud-init.cfg

```
# This file is generated from information provided by
# the datasource.  Changes to it will not persist across an instance.
# To disable cloud-init's network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
auto lo
iface lo inet loopback
    dns-nameservers 192.168.4.2
    dns-search maas

auto enp0s25
iface enp0s25 inet dhcp
    gateway 192.168.4.1
    mtu 1500
```

where the iface for `enp0s25` was changed from static to dhcp.

## Configure LXD Node
In order to deploy k8s on the lxd containers a few configurations must be set to the node that will then be inherited
to each of the containers deployed on that node. If you already ran your containers you can set these configurations to the
particular container itself after the fact, however, we recommend you just destroy the container and recreate it anyway.

Run the following script from the staging machine to set configurations. Note that this includes additional zfs configs
tht will allow access of the zfs device from the container, make changes as you require.
```
./configure_lxd_node <node-name>
```


# K8s nodes
As mentioned in the intro, each K8s node is defined to be a container running an ubuntu:16.04 image. Here
we describe how to create and destroy these


## Deploying K8s Ready Nodes

```
./deploy_k8s_nodes.sh nuc2-3 create authorized_keys init_k8s_nodes.sh
```

## Destroying K8s Ready Nodes

```
./deploy_k8s_nodes.sh nuc2-3 destroy
```

# Deploying K8s with juju
For your own cluster of physica nodes, as suggested in the getting ready section, we suggest you bootstrap
your own cloud.

## Bootstrap
Since a machine in our case was used to manage our nodes (via maas) we opted to bootstrap to that same machine.
That isnt necessary, but we found that to be convenient, and so the following was used to bootstrap:
  
```
juju bootstrap manual/192.168.4.2 mycloud
```

That should install your own controller from which you will deploy models etc..


## Create your own model
```
juju add-model k8s
```

## Manually add machines to be used in your model
```
juju add machine ssh:ubuntu@<ip-address>
```

The above should succeed for each machine and should add, in a sequential fashion, the machine you wish
to use in your cluster.


## Deploy K8s
```
juju deploy k8s-core-bundle.yaml --map-machines=existing,0=0,1=1
```
Where existing machines are those you had added in the manual add case. The file
`k8s-core-bundle` references the machines listed:

```
machines:
  '0':
    constraints: cores=2 mem=8G root-disk=16G
    series: xenial
  '1':
    constraints: cores=2 mem=8G root-disk=16G
    series: xenial
```
On each a service is deployed, for example

```
 kubernetes-worker:
    annotations:
      gui-x: '100'
      gui-y: '850'
    charm: cs:~containers/kubernetes-worker-118
    constraints: cores=2 mem=8G root-disk=16G
    expose: true
    num_units: 1
    options:
      channel: 1.10/stable
    to:
    - '1'
``` 

# Managing the K8s cluster
Here we include a few shortcuts to managing a cluster, you can readily find some of these suggestions 
## Enable RBAC
```
juju config kubernetes-master authorization-mode="RBAC,Node"
```

## Adding worker node
Adding a worker node is as simple as adding a machine to juju and then deploying `to` that machine
```
juju add-unit kubernetes-worker --to <machine-number>
```

# Destroying k8s
Here we point out the process of destroying a k8s cluster deployed with juju

## Manually remove a machine from your model
```
juju destroy-machine <machine-number> --force
```

## Manually remove model
```
juju destroy-model k8s
```


# References
- [1]  [Kuberentes Core Bundle](https://jujucharms.com/kubernetes-core/)
- [2]  [RBAC and Helm](https://github.com/kubernetes/helm/blob/master/docs/rbac.md)
- [3]  [Remote host](https://stgraber.org/2016/04/12/lxd-2-0-remote-hosts-and-container-migration-612/)
- [4]  [LXD Brideging](https://blog.simos.info/how-to-make-your-lxd-containers-get-ip-addresses-from-your-lan-using-a-bridge/)
- [5]  [Snap Interfaces](https://docs.snapcraft.io/core/interfaces)
- [6]  [Maas LXD Integration](https://github.com/lxc/lxd/blob/master/doc/containers.md)
- [7]  [LXD v3 configure for k8s deployment](https://github.com/juju-solutions/bundle-canonical-kubernetes/wiki/Deploying-on-LXD)
- [8]  [LXD, ZFS and bridged networking on Ubuntu 16.04 LTS+](https://bayton.org/docs/linux/lxd/lxd-zfs-and-bridged-networking-on-ubuntu-16-04-lts/)
- [9]  [Local Persistent Storage Example CDK on LXC](https://github.com/juju-solutions/bundle-canonical-kubernetes/wiki/Local-Persistent-Storage-Example)
- [10] [Local persistent volumes beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)
- [11] [K8s Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [12] [kubernetes-incubator/external-storage](https://github.com/kubernetes-incubator/external-storage/tree/master/local-volume#enabling-the-alpha-feature-gates)
- [13] [Local-Persistent-Storage-Example](https://github.com/juju-solutions/bundle-canonical-kubernetes/wiki/Local-Persistent-Storage-Example)
- [14] [Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)