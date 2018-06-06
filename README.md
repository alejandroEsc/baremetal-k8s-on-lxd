# baremetal-k8s-on-lxd
Here we include tools, at first bash scripts, that can be run to help provision baremetal running an lxd cluster, to
run Kubernetes (K8s). The approach here is to deploy ubuntu 16.04 containers accross an lxd cluster with constraints,
and have them be consumed by juju as machines that can be used to run kubernetes. 

# Getting Ready
We recommended the following setup

- One physical machine that will contain the juju controller, and a remote lxc instance to peek into the cluster. 
- All physical machines that you will run lxd containers, must run least lxd 3.0.0

Therefore you will have one machine that stages all changes accross your cluster. That same machine could be the maas controller
if you so wish.


To ensure, on ubuntu, that you have the latest lxd please run the following
```
sudo apt remove lxd
sudo apt remove lxd-client
sudo snap install lxd
```

# Setting up a new LXD node.

# K8s nodes
As mentioned in the intro, each K8s node is defined to be a container running an ubuntu:16.04 image. Here
we describe how to create and destroy these
## Deploying K8s Ready Nodes

## Destroying K8s Ready Nodes





