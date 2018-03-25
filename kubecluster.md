Setting up Raspberry Pi Kubernetes Cluster


* Date: **March 2018**
* Operating System: **Raspbian Sketch**
* Kernel: **4.9**


Follow notes at [Kubernetes on Raspberry Pi with .NET Core](https://medium.com/@mczachurski/kubernetes-on-raspberry-pi-with-net-core-36ea79681fe7)


## Kubernetes Dashboard Security

On your Kubernetes Master

Create a file called ” dashboard-admin.yaml “ with the following content: 


```
apiVersion: rbac.authorization.k8s.io/v1beta1 
kind: ClusterRoleBinding 
metadata: 
  name: kubernetes-dashboard 
  labels: 
    k8s-app: kubernetes-dashboard 
roleRef: 
  apiGroup: rbac.authorization.k8s.io 
  kind: ClusterRole 
  name: cluster-admin 
subjects: 
- kind: ServiceAccount 
  name: kubernetes-dashboard 
  namespace: kube-system 

```

then run 

```bash
kubectl create -f dashboard-admin.yaml 
```
