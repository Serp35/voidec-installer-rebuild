#!/bin/bash

xbps-reconfigure -f glibc-locales

echo "Let's create the root password"
echo ""
passwd
echo ""
read -p "Do you want to enable any service? (NetworkManager recommended) [y/N]: " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ "$answer" = "Yes" ] || [ "$answer" = "yes" ]; then
    echo ""
    ls /etc/sv/
    echo ""
    read -p "Which services do you want to enable? [exact name]: " service
    for i in $service; do
        ln -s /etc/sv/$i /var/service/
        sv start $i
    done
else
    echo "No services will be enabled."
fi
ln -s /etc/sv/dbus /var/service/

echo ""
echo "Let's install GRUB!"
while true; do
    read -p "What's your firmware type? [BIOS/UEFI]: " firmware
    echo ""
    if [ "$firmware" = "BIOS" ] || [ "$firmware" = "bios" ]; then
        xbps-install -S grub
        echo ""
        lsblk
        read -p "In which disk are you installing the system? [disk]: /dev/" disk
        grub-install /dev/$disk
        break
    elif [ "$firmware" = "UEFI" ] || [ "$firmware" = "uefi" ]; then
        xbps-install -S grub-x86_64-efi
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"
        break
    else
        echo "Invalid firmware"
    fi
done
echo "Grub installed!"
xbps-reconfigure -fa
echo ""
read -p "Do you want to add any users? [Y/n]: " answer
if [ "$answer" = "n" ] || [ "$answer" = "N" ]; then
    echo "No users will be added"
else
    echo -n "How would you want to name the new user? [user name]: "
    read user
    echo ""
    useradd -m $user
    passwd $user
    echo ""
    while true; do
        echo -n "Do you want to give sudo permissions to the user? [Y/n]: "
        read sudo
        if [ "$sudo" == "Y" ] || [ "$sudo" == "y" ]; then
            break
        elif [ "$sudo" == "n"]; then
            break
        else
            echo "$sudo is an invalid option. Take care of capital letters."
        fi
    done
    if [ "$sudo" == "Y" ] || [ "$sudo" == "y" ]; then
        xbps-install -Sy sudo
        echo "$user   ALL=(ALL:ALL) ALL" >> etc/sudoers
        echo "$user is a sudoer."
    fi
fi
echo "Installing rebuild command..."
mv /rebuild.sh /usr/local/bin/voidec-rebuild
echo "Generating /etc/void/configuration.void..."
voidec-rebuild generate
echo "You can now exit and shutdown!"
echo "Don't forget to update after that! (xbps-install -Syu)"

