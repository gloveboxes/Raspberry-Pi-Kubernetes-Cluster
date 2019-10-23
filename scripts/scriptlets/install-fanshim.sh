CHECKPOINT='~/.node-FanSHIM-completed'

if [ -f "$CHECKPOINT" ]; then
    echo "Fan SHIM already installed"
    exit 0
fi

sleep 2 # let system settle

while : ;
do
    sudo apt-get install -y python3-pip
    if [ $? -eq 0 ]
    then
        break
    else
        echo "\nFanSHIM installation failed. Retrying in 10 Seconds\n"
        sleep 10
    fi
done

cd ~/

while : ;
do
    wget https://github.com/pimoroni/fanshim-python/archive/master.zip
    if [ $? -eq 0 ]
    then
        break
    else
        echo "\nFanSHIM installation failed. Retrying in 10 Seconds\n"
        sleep 10
    fi
done


unzip ~/master.zip
rm ~/master.zip

cd fanshim-python-master

sudo ./install.sh
if [ $? -ne 0 ]
then
    echo "\nFanSHIM installation failed. Retrying in 10 Seconds\n"
    sleep 10
    continue
fi

cd examples
sudo ./install-service.sh --on-threshold 65 --off-threshold 55 --delay 2

touch $CHECKPOINT