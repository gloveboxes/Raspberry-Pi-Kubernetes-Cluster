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
fi