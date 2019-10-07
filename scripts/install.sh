#!/bin/bash

while true; do
    echo ""
    read -p "Kubernetes Master or Node Set Up? ([M]aster, [N]ode), [Q]uit: " PyLab_Setup_Mode
    case $PyLab_Setup_Mode in
        [Mm]* ) break;;
        [Nn]* ) break;;
        [Qq]* ) exit 1;;
        * ) echo "Please answer yes(y), no(n), or quit(q).";;
    esac
done

if [ $PyLab_Setup_Mode = 'M' ] || [ $PyLab_Setup_Mode = 'm' ]; then   
    ./install-master-node.sh
else 
    ./install-node.sh
fi



