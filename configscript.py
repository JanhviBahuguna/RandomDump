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

if __name__ == '__main__':
    invoke_deployment()
