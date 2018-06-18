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

Create local storage class:
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

Next create a local persistent volume that can be consumed by a pvc
or dynamically by a container/pod:
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-local-pv
spec:
  capacity:
    storage: <storage-amount, e.g., 2Gi>
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: < path,e.g.,/mnt/disks/vol1>
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <node-where-volume-exists>
```

A pvc can then be written as:
```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: example-local-claim
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: <storage-amount, e.g., 2Gi>
  selector:
    matchExpressions:
    - key: kubernetes.io/hostname
      operator: In
      values:
      - nuc-ae-c-ubuntu-2CPU-8GB-4

``` 

## Primarily using juju


