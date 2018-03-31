Setting up Raspberry Pi Kubernetes Cluster


* Date: **March 2018**
* Operating System: **Raspbian Sketch**
* Kernel: **4.9**


Follow notes at [Kubernetes on Raspberry Pi with .NET Core](https://medium.com/@mczachurski/kubernetes-on-raspberry-pi-with-net-core-36ea79681fe7)



## Memory Optimisation

if using Raspberry Pi Lite (Headless) you can reduce the memory split between the GPU and the rest of the system down to 16mb.

```bash
sudo nano /boot/cmdline.txt
```
add the following to the end of the line (don't add to a new line)


**cgroup_enable=cpuset cgroup_enable=memory**

 WORK IN PROGRESS - NOT WORKING ATM


sudo kubeadm init --pod-network-cidr=10.244.0.0/16

sudo kubeadm init --apiserver-advertise-address=192.168.2.1 --token-ttl 0

sudo kubeadm init --apiserver-advertise-address=192.168.0.135 --token-ttl 0

kubectl apply -f https://git.io/weave-kube-1.6



## Setup Nodes





When the kubeadm init command completes you need to take a note of the token. You use this command to join a node to the kubernetes master.

```bash
$ sudo kubeadm join 192.168.2.1:6443 --token hy15wr.pyfx1d8xbec6f0hw --discovery-token-ca-cert-hash sha256:ab6224e85966f1bf5f7ad2446a08af4a24fc8c510c8aa5df353c76f6b8cb938f
```


kubectl apply -f \
 "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

## Reseting Kubernetes Master or Node

````bash
$ sudo kubeadm reset
$ sudo systemctl restart kubelet.service
````

## Useful Kubernetes Commands

```bash
$ kubectl get pods --namespace=kube-system -o wide

$ kubectl get nodes

$ for i in range{1..1000}; do date; kubectl get pods --namespace=kube-system -o wide;sleep 5; done;

```

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


## SSH Tunnel to Cluster Master

sudo ssh -L 8080:10.101.166.227:80 pi@192.168.0.142

