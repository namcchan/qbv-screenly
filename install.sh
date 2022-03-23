#!/bin/bash -e

# vim: tabstop=4 shiftwidth=4 softtabstop=4
# -*- sh-basic-offset: 4 -*-

REPOSITORY=https://github.com/namcchan/screenly.git

sudo mkdir -p /etc/ansible
echo -e "[local]\nlocalhost ansible_connection=local" | sudo tee /etc/ansible/hosts > /dev/null

if [ ! -f /etc/locale.gen ]; then
    # No locales found. Creating locales with default UK/US setup.
    echo -e "en_GB.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" | sudo tee /etc/locale.gen > /dev/null
    sudo locale-gen
fi

sudo sed -i 's/apt.screenlyapp.com/archive.raspbian.org/g' /etc/apt/sources.list
sudo apt update -y
sudo apt-get purge -y \
    python-pyasn1
sudo apt-get install -y  --no-install-recommends \
    git-core \
    libffi-dev \
    libssl-dev \
    python-dev \
    python-pip \
    python-setuptools \
    python-wheel \
    whois

sudo apt-get install -y network-manager

# Install Ansible from requirements file.
ANSIBLE_VERSION=ansible==2.8.8

sudo pip install "$ANSIBLE_VERSION"

sudo -u pi ansible localhost \
    -m git \
    -a "repo=$REPOSITORY dest=/home/pi/screenly force=no"
cd /home/pi/screenly/ansible

sudo -E ansible-playbook site.yml

# Pull down and install containers
# chmod +x /home/pi/screenly/bin/upgrade_containers.sh
# /home/pi/screenly/bin/upgrade_containers.sh

sudo apt-get autoclean
sudo apt-get clean
# sudo docker system prune -f
sudo apt autoremove -y
sudo apt-get install plymouth --reinstall -y
sudo find /usr/share/doc \
    -depth \
    -type f \
    ! -name copyright \
    -delete
sudo find /usr/share/doc \
    -empty \
    -delete
sudo rm -rf \
    /usr/share/man \
    /usr/share/groff \
    /usr/share/info/* \
    /usr/share/lintian \
    /usr/share/linda /var/cache/man
sudo find /usr/share/locale \
    -type f \
    ! -name 'en' \
    ! -name 'de*' \
    ! -name 'es*' \
    ! -name 'ja*' \
    ! -name 'fr*' \
    ! -name 'zh*' \
    -delete
sudo find /usr/share/locale \
    -mindepth 1 \
    -maxdepth 1 \
    ! -name 'en*' \
    ! -name 'de*' \
    ! -name 'es*' \
    ! -name 'ja*' \
    ! -name 'fr*' \
    ! -name 'zh*' \
    ! -name 'locale.alias' \
    -exec rm -r {} \;

sudo chown -R pi:pi /home/pi

# Run sudo w/out password
if [ ! -f /etc/sudoers.d/010_pi-nopasswd ]; then
  echo "pi ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_pi-nopasswd > /dev/null
  sudo chmod 0440 /etc/sudoers.d/010_pi-nopasswd
fi

echo -e "Screenly version: $(git rev-parse --abbrev-ref HEAD)@$(git rev-parse --short HEAD)\n$(lsb_release -a)" > ~/version.md

echo "Installation completed."

sleep 5

sudo reboot
