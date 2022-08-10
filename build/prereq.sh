#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root."
  exit 1
fi

APT_UPDATE=false

run_apt_update () {
  apt update
}

run_apt_install () {
  apt install -y $1
}

run_auto_install() {
  if [ "$APT_UPDATE" = false ]; then
    echo "[*] Updating apt sources"
    run_apt_update
    APT_UPDATE=true
  fi
    echo "[*] Running apt install $1"
    run_apt_install $1
}

auto_install_question () {
  while true; do
      read -p "$1 is not installed. Do you wish to install this program (Y/n)? " yn
      case $yn in
          [Yy]* ) run_auto_install $1; break;;
          [Nn]* ) exit;;
          * ) run_auto_install $1; break;;
      esac
  done

}

is_package_installed () {
  for pkg in $1; do
    status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
      auto_install_question $pkg
    else
      echo "$pkg is installed."
    fi
  done
}

if [ "$(grep -Ei 'debian|buntu' /etc/*release)" ]; then
   is_package_installed \
   'debootstrap squashfs-tools xorriso isolinux syslinux-efi grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools git gcc make liblzma-dev wget unzip'
else
  echo "This script can only be run on a Debian or Ubuntu machine."
  exit 1
fi
