sudo apt update && sudo apt install -y git

git clone https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster.git ~/kube-setup

cd ~/kube-setup/scripts
sudo chmod +x *.sh
./kube-master-setup.sh