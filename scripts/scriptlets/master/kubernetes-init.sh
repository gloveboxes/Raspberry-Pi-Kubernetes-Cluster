# Preload the Kubernetes images
# echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
# kubeadm config images pull

echo -e "\nInitialising Kubernetes Master - This will take a few minutes. Be patient:)\n"

# Set up Kubernetes Master Node
sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0 --skip-token-print

# make kubectl generally available
rm -r -f $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "sudo $(kubeadm token create --print-join-command --ttl 0)" > ~/k8s-join-node.sh