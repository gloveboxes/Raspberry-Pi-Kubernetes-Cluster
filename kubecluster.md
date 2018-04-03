Setting up Raspberry Pi Kubernetes Cluster


* Date: **April 2018**
* Operating System: **Raspbian Sketch**
* Kernel: **4.9**


Follow notes at [Kubernetes on Raspberry Pi with .NET Core](https://medium.com/@mczachurski/kubernetes-on-raspberry-pi-with-net-core-36ea79681fe7)

## Install Docker

```bash
curl -sSL get.docker.com | sh && sudo usermod pi -aG docker
```

## Disable Virtual Memory

```bash
sudo dphys-swapfile swapoff && \
sudo dphys-swapfile uninstall && \
sudo update-rc.d dphys-swapfile remove
```

## Memory Optimisation

If using Raspberry Pi Lite (Headless) you can reduce the memory split between the GPU and the rest of the system down to 16mb.

```bash
echo "gpu_mem=16" | sudo tee -a /boot/config.txt
```


## Enable cgroups for kubernetes

Append cgroup_enable=cpuset cgroup_enable=memory to the end of the line of /boot/cmdline.txt file.

```bash
sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory/' /boot/cmdline.txt
```

## Install Kubernetes

Copy the next complete block of commands and paste in to the Raspberry Pi Terminal.

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update -q && \
sudo apt-get install -qy kubeadm
```

## Reboot

Reboot so configuration changes made above take effect.

```bash
sudo reboot
```

## Initialise an instance of a Kubernetes Master Node

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.2.1 --token-ttl 0
```

Note, using a --token-ttl 0 is not recommended for production environments. It's fine and simplifies a development/test environment.


## Weave

```bash
kubectl apply -f https://git.io/weave-kube-1.6
```



## Setup Nodes

When the kubeadm init command completes you need to take a note of the token. You use this command to join a node to the kubernetes master.

```bash
$ sudo kubeadm join 192.168.2.1:6443 --token hy15wr.pyfx1d8xbec6f0hw --discovery-token-ca-cert-hash sha256:ab6224e85966f1bf5f7ad2446a08af4a24fc8c510c8aa5df353c76f6b8cb938f
```


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

ssh -f -N -L 8080:10.101.166.227:80 pi@192.168.0.142

ssh -L 8080:10.101.213.96:80 pi@192.168.0.129
10.101.213.96 


https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys

http://kamilslab.com/2016/12/17/how-to-set-up-ssh-keys-on-the-raspberry-pi/




## Exercise .NET App

```bash
or i in {1..1000000}; do curl http://192.168.0.142:8002/api/values; echo $i; done
```