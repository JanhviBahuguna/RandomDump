from io import StringIO
from io import StringIO
import json
import netmiko
import paramiko
import time
from azure.keyvault import KeyVaultClient
from azure.identity import CertificateCredential
from azure.keyvault.secrets import SecretClient
from OpenSSL import crypto


firewall_ip = "10.11.0.4"
device_username = "azureuser"
device_password = "TestingMyself@1"

def construct_valid_rsa_key(rsa_key_string):
    begin_rsa_key  = '-----BEGIN RSA PRIVATE KEY-----'
    end_rsa_key    = '-----END RSA PRIVATE KEY-----'
    rsa_key_string = rsa_key_string.strip(begin_rsa_key)
    rsa_key_string = rsa_key_string.strip(end_rsa_key)
    rsa_key_string = rsa_key_string.replace(" ","\n")
    rsa_key_string = begin_rsa_key + "\n" + rsa_key_string + "\n" + end_rsa_key
    nva_vm_ssh_private_key = StringIO(rsa_key_string)
    nva_vm_private_key =  paramiko.RSAKey.from_private_key(nva_vm_ssh_private_key)
    return nva_vm_private_key


def connect_to_cisco_asav(firewall_ip, pkey):
    try:
        config = {
                    'device_type'           : "cisco_asa",
                    'host'                  :  firewall_ip  ,
                    'username'              : device_username,
                    'password'              : device_password,
                    'use_keys'              : 'True',
                    'pkey'                  :  pkey,
                    'port'                  : 22,
                    'fast_cli'              : False,
                    'disabled_algorithms'   : {'pubkeys': ['rsa-sha2-256', 'rsa-sha2-512']}
                }

        ssh_device_connect_handler = netmiko.ConnectHandler(**config)
        return ssh_device_connect_handler
    except Exception as e:
        print("Failed to connect to the device using the given configuration, error".format(e))
        raise e

file_path = 'secret.txt'

with open(file_path, 'r') as file:
    file_content = file.read()
print(file_content)
rsa_key = construct_valid_rsa_key(file_content)
print(rsa_key)
ssh_device_connect_handler = connect_to_cisco_asav(firewall_ip, rsa_key)
