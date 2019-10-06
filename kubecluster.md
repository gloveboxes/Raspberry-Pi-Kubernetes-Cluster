# Setting up Raspberry Pi Kubernetes Cluster

ref https://github.com/codesqueak/k18srpi4

* Date: **Oct 2019**
* Operating System: **Raspbian Buster**
* Kernel: **4.19**

Follow notes at:

1. [Kubernetes on Raspberry Pi with .NET Core](https://medium.com/@mczachurski/kubernetes-on-raspberry-pi-with-net-core-36ea79681fe7)

2. [k8s-pi.md ](https://codegists.com/snippet/shell/k8s-pimd_elafargue_shell)

## Rename and Update your Raspberry Pi

```bash
read -p "Name your Raspberry Pi (eg k8smaster, k8snode1, ...): " RPINAME && \
sudo raspi-config nonint do_hostname $RPINAME && \
sudo apt update && sudo apt upgrade -y && sudo reboot

```

## Ensure iptables tooling does not use the nftables backend

- [Installing kubeadm on Debian Buster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [kube-proxy currently incompatible with `iptables >= 1.8`](https://github.com/kubernetes/kubernetes/issues/71305)

```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy && \
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

### Test iptables in legacy mode

```bash
iptables -V

returns iptables v1.8.2 (legacy)
```

## Kubernetes Prerequisites

1. Disable Swap
    Required for Kubernetes on Raspberry Pi
2. Optimise Memory
    If using Raspberry Pi Lite (Headless) you can reduce the memory split between the GPU and the rest of the system down to 16mb.
3. Enable cgroups
    Append cgroup_enable=cpuset cgroup_enable=memory to the end of the line of /boot/cmdline.txt file.

```bash
sudo dphys-swapfile swapoff && \
sudo dphys-swapfile uninstall && \
sudo systemctl disable dphys-swapfile && \
echo "gpu_mem=16" | sudo tee -a /boot/config.txt && \
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt
```

## Install Docker

```bash
curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker && sudo reboot
```

## Install Kubernetes

Copy the next complete block of commands and paste in to the Raspberry Pi Terminal.

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update -q && \
sudo apt-get install -qy kubeadm && \
sudo reboot
```

## Pull Kubernetes Images (Optional)

Optional, but useful as you can see th images being pulled. If you don't do here the images will be pulled by Kubeadmin init.

```bash
kubeadm config images pull
```

## Kubernetes Master and Node Set Up

Follow the next section to install the Kubernetes Master, else skip to [Kuberntes Node Set Up](#kubernetes-node-set-up)

### Kubernetes Master Set Up

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0
```

Notes:

1. For flannel to work, you must pass --pod-network-cidr=10.244.0.0/16 to kubeadm init.
2. Using a --token-ttl 0 is not recommended for production environments. It's fine and simplifies a development/test environment.

#### Make the install generally available

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### Install Flannel Pod Network add-on

[Creating a single control-plane cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

```bash
sudo sysctl net.bridge.bridge-nf-call-iptables=1 && \
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml
```

### Kubernetes Node Set Up

When the kubeadm init command completes you need to take a note of the token. You use this command to join a node to the kubernetes master.

```bash
sudo sysctl net.bridge.bridge-nf-call-iptables=1 
```

```bash
sudo kubeadm join 192.168.2.1:6443 --token ......
```

## Resetting Kubernetes Master or Node

````bash
sudo kubeadm reset && \
sudo systemctl daemon-reload && \
sudo systemctl restart kubelet.service
````

## Useful Kubernetes Commands

```bash
kubectl get pods --namespace=kube-system -o wide

kubectl get nodes

for i in range{1..1000}; do date; kubectl get pods --namespace=kube-system -o wide;sleep 5; done;
```

## Allow Pods on Master

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-  
```


## Kubernetes Dashboard Security

On your Kubernetes Master

Create a file called ” dashboard-admin.yaml “ with the following content:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
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

ssh -f -N -L 8080:10.101.166.227:80 pi@192.168.0.150



https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys

http://kamilslab.com/2016/12/17/how-to-set-up-ssh-keys-on-the-raspberry-pi/

```bash
ssh-copy-id username@remote_host
```


## Exercise .NET App

```bash
for i in {1..1000000}; do curl http://192.168.0.142:8002/api/values; echo $i; done
```


```bash
nslookup netcoreapi.default.svc.cluster.local 
```



## Docker Build Process

```bash
docker build -t netcoreapi .
docker tag netcoreapi glovebox/netcoreapi:v002
docker push glovebox/netcoreapi:v002

```


### Update Kubernetes Image

[Interactive Tutorial - Updating Your App](https://kubernetes.io/docs/tutorials/kubernetes-basics/update-interactive/)

```bash
kubectl set image deployments/netcoreapi-deployment netcoreapi=glovebox/netcoreapi:v002
```



## MySQL on Raspberry Pi

https://hub.docker.com/r/hypriot/rpi-mysql/

## References

https://blog.alexellis.io/test-drive-k3s-on-raspberry-pi/

https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/

https://www.syncfusion.com/ebooks/using-netcore-docker-and-kubernetes-succinctly

https://itnext.io/building-a-kubernetes-cluster-on-raspberry-pi-and-low-end-equipment-part-1-a768359fbba3

function.yml https://github.com/teamserverless/k8s-on-raspbian/blob/master/GUIDE.md

NFS  
https://itnext.io/building-an-arm-kubernetes-cluster-ef31032636f9