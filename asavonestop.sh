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
  sudo apt install -y net-tools
  sudo apt install -y iperf3
  sudo crontab -l > cron_bkp
  sudo echo "*/1 * * * * sudo /sbin/route add -net $subnet gw $gateway > /var/log/nva.log 2>&1" >> cron_bkp
  sudo crontab cron_bkp
  sudo rm cron_bkp
  route
  sleep 70
  route
}

configure_nva_python(){
  install_python_packages
  $PYTHON - <<END
from io import StringIO
import json
import netmiko
import paramiko
import time
from azure.keyvault import KeyVaultClient
from azure.identity import CertificateCredential
from azure.keyvault.secrets import SecretClient
from OpenSSL import crypto


# Firewall & VM Configurations
firewall_ip = "10.11.0.4"
device_username = 'azureuser'
device_password = 'TestingMyself@1'

#Commands to be executed
configuration_command = ['interface gi0/0','nameif inside','security-level 0','ip address 10.11.1.4 255.255.255.0','no shutdown','same-security-traffic permit inter-interface','interface gi0/1','nameif outside','security-level 0','ip address 10.11.2.4 255.255.255.0','no shutdown','same-security-traffic permit inter-interface','access-list all_traffic extended permit ip any any','access-group all_traffic global','wr mem']

def connect_to_cisco_asav(firewall_ip):
    try:
        config = {
                    'device_type'           : "cisco_asa",
                    'host'                  :  firewall_ip  ,
                    'username'              : device_username,
                    'password'              : device_password,
                    'port'                  : 22,
                    'fast_cli'              : False,
                    'disabled_algorithms'   : {'pubkeys': ['rsa-sha2-256', 'rsa-sha2-512']}
                }

        ssh_device_connect_handler = netmiko.ConnectHandler(**config)
        return ssh_device_connect_handler
    except Exception as e:
        print("Failed to connect to the device using the given configuration, error".format(e))
        raise e

def print_console_output(msg, std_output):
    print("################################################################################################################")
    print(msg)
    print("----------------------------------------------------------------------------------------------------------------")
    print(std_output)

def invoke_deployment():
    try:
        ssh_device_connect_handler = connect_to_cisco_asav(firewall_ip)
        ssh_device_connect_handler.enable()
        stdout_interface_1 = ssh_device_connect_handler.send_command("show running-config interface gi0/0")
        stdout_interface_2 = ssh_device_connect_handler.send_command("show running-config interface gi0/1")

        print_console_output("Interface Detail for gi0/0 before config set", stdout_interface_1)
        print_console_output("Interface Detail for gi0/1 before config set", stdout_interface_2)

        output_config_command = ssh_device_connect_handler.send_config_set(configuration_command)

        print_console_output("Output of config set command:", output_config_command)

        stdout_interface_1 = ssh_device_connect_handler.send_command("show running-config interface gi0/0")
        stdout_interface_2 = ssh_device_connect_handler.send_command("show running-config interface gi0/1")

        print_console_output("Interface Detail for gi0/0 after config set", stdout_interface_1)
        print_console_output("Interface Detail for gi0/1 after config set", stdout_interface_2)

    except Exception as e:
        print("Failed to run commands on the VM, error: {0}".format(e))

invoke_deployment()
END
}

configure_client_nva_server_scenario() {
  config_script=$1
  subnet1=$2 #server subnet
  gateway1=$3 #client gateway

  echo "Ubuntu Client VM Start"
  add_route "$subnet1" "$gateway1"
  configure_nva_python
  echo "Ubuntu Client VM End"
}

echo "***Configuring NVAs Started***"
configure_client_nva_server_scenario "https://raw.githubusercontent.com/JanhviBahuguna/RandomDump/refs/heads/main/configscript.py" "10.11.2.0/24" "10.11.1.1"
echo "***Configuring NVAs Done***"
