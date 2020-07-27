#!/bin/bash

echo -e "\nInstalling Docker\n"
# Install Docker
sudo docker --version
if [ $? -ne 0 ]
then
    while : ;
    do
        curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker
        if [ $? -eq 0 ]
        then
            break
        else
            echo -e "\nDocker installation failed. Check internet connection. Retrying in 10 seconds.\n"
            sleep 10
        fi
    done

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# sudo systemctl enable docker

fi

sudo reboot