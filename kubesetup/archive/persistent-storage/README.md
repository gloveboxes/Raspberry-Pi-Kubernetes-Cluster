<!-- https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client -->

# Kubernetes NFS-Client Provisioner

## Deploy NFS-Client provisioner

Creates a NFS Client Provisioning Service named **nfs-client-provisioner**

```bash
kubectl apply -f nfs-client-deployment-arm.yaml
```

## Create Storage Class

Creates a storage class named **managed-nfs-storage**

```bash
kubectl apply -f storage-class.yaml
```

## Check Storage Class

```bash
kubectl get storageclass
```

## Create a Persistent Volume

Creates a persistent volume named **glovebox**

```bash
kubectl apply -f persistent-volume.yaml
```

### Check Persistent Volume

```bash
kubectl get pv
```

## Create a Persistent Volume Claim

Creates a persistent volume named **glovebox-claim**

```bash
kubectl apply -f persistent-volume-claim.yaml
```

### Check Persistent Volume Claims

```bash
kubectl get pv
```

## Test Storage

[Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

```bash
kubectl apply -f nginx-test-pod.yaml
```

### Verify that the Container in the Pod is running

```bash
kubectl get pod
```

### Verify Service running

```bash
kubectl get svc
```

From web browser or curl verify pulling **index.html** from NFS Server

## Useful Commands

```bash
kubectl exec -it task-pv-pod -- /bin/bash
```
