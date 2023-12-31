#!/bin/sh
# Install Ansible on the VM (if it's not already installed).
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-get install -y ansible

echo "Begin Initialization"
echo "---------------------"

touch /home/adminuser/ansible-playbook.yaml

cat > /home/adminuser/ansible-playbook.yaml <<- EOF
---
- name: Install Ansible
  hosts: all
  become: true
  gather_facts: false

  tasks:
    - name: Install dependencies
      apt:
        name: "{{ packages }}"
        state: present
      vars:
        packages:
          - software-properties-common

    - name: Add Ansible repository (Ubuntu)
      apt_repository:
        repo: "ppa:ansible/ansible"

    - name: Install Ansible
      apt:
        name: ansible
        state: latest
      when: ansible_os_family == 'Debian'  # For Debian-based systems

    - name: Add Ansible repository (RHEL)
      yum_repository:
        name: ansible
        description: "Ansible repository"
        baseurl: "https://releases.ansible.com/rpm/release/epel-$releasever/x86_64/"
        gpgcheck: no

    - name: Install Ansible
      yum:
        name: ansible
        state: latest
      when: ansible_os_family == 'RedHat'  # For Red Hat-based system
EOF

cat > /home/adminuser/ansible-playbook.yaml <<- EOF
---
- name: Install WireGuard on Ubuntu
  hosts: localhost
  become: yes

  vars:
    wireguard_interface_name: wg0
    wireguard_private_key_path: /etc/wireguard/privatekey
    wireguard_public_key_path: /etc/wireguard/publickey
    wireguard_endpoint: ${azurerm_public_ip}:51820
    wireguard_allowed_ips: 10.0.0.0/24  # Replace this with your desired client subnet

  tasks:
    - name: Install WireGuard package
      apt:
        name: wireguard
        state: present

    - name: Generate WireGuard private key
      command: "umask 077 && wg genkey | tee {{ wireguard_private_key_path }}"
      register: wireguard_private_key
      changed_when: wireguard_private_key.rc == 0

    - name: Generate WireGuard public key
      command: "echo {{ wireguard_private_key.stdout }} | wg pubkey | tee {{ wireguard_public_key_path }}"
      when: wireguard_private_key.changed

    - name: Configure WireGuard interface
      lineinfile:
        path: /etc/wireguard/{{ wireguard_interface_name }}.conf
        create: yes
        line: |
          [Interface]
          PrivateKey = {{ lookup('file', wireguard_private_key_path) }}
          Address = {{ wireguard_allowed_ips }}
          ListenPort = 51820

      notify: Restart WireGuard

    - name: Add WireGuard endpoint configuration
      lineinfile:
        path: /etc/wireguard/{{ wireguard_interface_name }}.conf
        line: "Endpoint = {{ wireguard_endpoint }}"

      notify: Restart WireGuard

    - name: Enable IP forwarding
      sysctl:
        name: net.ipv4.ip_forward
        value: 1
        state: present

    - name: Ensure IP forwarding is enabled permanently
      lineinfile:
        path: /etc/sysctl.conf
        line: "net.ipv4.ip_forward = 1"
      when: ansible_distribution == "Ubuntu"

    - name: Enable WireGuard service
      systemd:
        name: "wg-quick@{{ wireguard_interface_name }}"
        enabled: yes
        state: started

  handlers:
    - name: Restart WireGuard
      systemd:
        name: "wg-quick@{{ wireguard_interface_name }}"
        state: restarted
EOF

ansible-playbook /home/adminuser/ansible-playbook.yml