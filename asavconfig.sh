#!/bin/bash

PYTHON=python3.8

install_python_packages(){

  echo "***Installing $PYTHON and related modules ***"
  sudo apt-get update
  sudo apt install -y $PYTHON python3-pip
  # Sometimes the DNS is not resolved and python and pip are not installed in the first try.
  sleep 60
  sudo apt install -y $PYTHON python3-pip

  $PYTHON -m pip install -U pip
  $PYTHON -m pip install --ignore-installed PyYAML
  $PYTHON -m pip install setuptools_rust
  $PYTHON -m pip install azure-identity
  $PYTHON -m pip install azure-keyvault-secrets
  $PYTHON -m pip install netmiko==4.1.0
  $PYTHON -m pip install azure-keyvault==1.1.0
  $PYTHON -m pip install cryptography==37.0.2
  $PYTHON -m pip install msrestazure==0.5.0
  $PYTHON -m pip install adal==1.2.4
}

add_route() {
  subnet=$1
  gateway=$2

  echo "*** Adding route to $subnet via $gateway ***"
  sudo apt install net-tools
  sudo apt install iperf3
  sudo crontab -l > cron_bkp
  echo "*/1 * * * * sudo /sbin/route add -net $subnet gw $gateway > /var/log/nva.log 2>&1" >> cron_bkp
  sudo crontab cron_bkp
  sudo rm cron_bkp
  route
  sleep 70
  route
}

configure_client_nva_server_scenario() {
  config_script=$1
  subnet1=$2 #server subnet
  gateway1=$3 #client gateway

  echo "Ubuntu Client VM Start"
  add_route "$subnet1" "$gateway1"
  install_python_packages
  echo "Running python configuration script on the NVA"
  $PYTHON "$config_script"
  echo "Ubuntu Client VM End"
}

echo "***Configuring NVAs Started***"
configure_client_nva_server_scenario "https://raw.githubusercontent.com/JanhviBahuguna/RandomDump/refs/heads/main/configscript.py" "10.11.2.0/24" "10.11.1.1"
echo "***Configuring NVAs Done***"
