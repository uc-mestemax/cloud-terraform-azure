# Hashicorp Vault Provisioning


## High Level Overview

``` mermaid
Components of my Project
    A[Terraform] -->|Provisions Azure Virtual Machine and Dependencies| B(Ansible Install)
    B --> C{Ansible Playbook}
    C -->|One| D[Wireguard VPN]
    C -->|Two| E[Hashicorp Vault]
    C -->|Three| F[fa:fa-car Off to the Races!]
```

## Interacting With My Vault

This repo configures a VPN server using the Wireguard application to connect my client device to my Azure resources.

```powershell
..\terraform.exe apply
ssh-keygen -t ed25519 -C "Azure-Terraform-Key" -b 4096 -N
ssh-keygen -t ed25519 -C "Azure-Terraform-Key" -b 4096
ssh-keygen -t ed25519 -C "Azure-Terraform-Key" -b 4096
..\terraform.exe apply
ssh-keygen -t rsa -C "Azure-Terraform-Key" -b 4096
rm .\mykey .\mykey.pub .\azurekey.key .\azurekey.pub

rm .\mykey, .\mykey.pub, .\azurekey.key,.\azurekey.pub

ssh-keygen -t rsa -C "Azure-Terraform-Key" -b 4096

..\terraform.exe apply

az account list --query "[?user.name=='mestemax@mail.uc.edu'].{Name:name, ID:id, Default:isDefault}" --output Table

az login

..\terraform.exe apply
```


