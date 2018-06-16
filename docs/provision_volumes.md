#Provisioning Volumes in K8s

There are multiple ways to provision volumes
# Setting up K8s for local external volumes
K8s requires additional extras in form of `feature-gates` to allow access of local volumes.
How one opted to provision kubernetes will determine how you would reset the 
components, e.g., for juju one would run the following commands:

```
juju config kubernetes-master scheduler-extra-args="feature-gates=PersistentLocalVolumes=true,MountPropagation=true,VolumeScheduling=true,BlockVolume=true"
```

```
juju config kubernetes-master api-extra-args="feature-gates=PersistentLocalVolumes=true,MountPropagation=true,VolumeScheduling=true,BlockVolume=true"
```

```
juju config kubernetes-master controller-manager-extra-args="feature-gates=PersistentLocalVolumes=true,MountPropagation=true,VolumeScheduling=true,BlockVolume=true"
```

```
juju config kubernetes-worker kubelet-extra-args="feature-gates=BlockVolume=true"
```
# Example 

# Methods to allow local storage

## Local LXD Storage
Here
```
lxc storage volume create zfs-ebs nuc2-2-vol-1 --target nuc2-2
```

```
lxc storage volume create zfs-ebs nuc2-2-vol-1 --target nuc2-2
```

```
lxc storage volume attach zfs-ebs nuc2-2-vol-2 nuc2-2-ubuntu-2CPU-8GB-2 /mnt/disks/vol1
```

```
lxc storage volume list zfs-ebs
```


## Primarily using JUJU


