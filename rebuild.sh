#!/bin/bash
if [ "$1" = "switch" ] || [ "$1" = "-s" ]; then
	if [ "$#" -eq 0 ]; then
		echo " No arguments given, rebuilding..."
	fi
	cp /etc/voidec/configuration.void /etc/voidec/backup/configuration/configuration.void_$(date +%Y-%m-%d-%H-%M-%S)

	packages=($( awk '/DAEMON/ {exit} {print}' /etc/voidec/configuration.void | grep -v "[PACKAGES]" ))
	daemons=($(awk '/DAEMONS/ {found=1; next} found' /etc/voidec/configuration.void ))

	#echo " Looking for packages to install..."
	echo ""

	for paquete in "${packages[@]}"; do 
	    if [ "$(xbps-query -m |  sed 's/-[^-]*$//' | grep -w "$paquete" )" ]; then
            sleep 0
            else
            noinstalled+=($paquete)
	    fi
	done

	if [ "${noinstalled}" ]; then
	    echo " I will install: ${noinstalled[@]}"
        if [ "$2" = "-y" ]; then
            echo " Is that correct? [y/n]: y"
        else
            read -p " Is that correct? [y/n]: " answer
        fi

	    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ] || [ "$2" = "-y" ]; then
		xbps-install -y ${noinstalled[@]} > /dev/null
		echo " Successfully installed ${noinstalled[@]} !"
		echo ""
	    else
		echo " Aborting"
		exit
	    fi
	else
	    echo " No packages need to be installed" && echo ""
	fi


	#echo " Looking for packages to remove..."
	echo ""

	installed=$(xbps-query -m|  sed 's/-[^-]*$//' )
	original_installed="$installed"  

	for paquete in "${packages[@]}"; do
	    installed="$(echo "$installed" | grep -vw "$paquete" )"
	done
	if [ "$installed" ]; then
		echo " We are going to remove: $(echo $installed | paste -sd ' ') "
        if [ "$2" = "-y" ]; then
            echo " Is that correct? [y/n]: y"
        else
            read -p " Is that correct? [y/n]: " answer
        fi

	    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ]|| [ "$2" = "-y" ]; then
		xbps-remove -y $installed > /dev/null
		echo " Successfully removed $(echo $installed | paste -sd ' ' ) !"
		echo ""
	    else
		echo " Aborting"
		exit
	    fi
	else
	    echo " No packages need to be removed."
	    echo ""
	fi

	# echo " Looking for daemons that must be activated..."
	echo ""
	activatingdaemons=()

	for daemon in "${daemons[@]}"; do
	    if [ -d "/var/service/$daemon" ]; then
		sleep 0
	    else
		existingdaemons="$(ls /etc/sv | grep -w $daemon)"
		if [ -d /etc/sv/$daemon ]; then
		    activatingdaemons+=($daemon)
		else 
		    echo " The daemon $daemon does not exist"
		    exit
		fi
	    fi
	done


	if [ "${activatingdaemons}" ]; then
	    echo " We will activate ${activatingdaemons[@]}"
        if [ "$2" = "-y" ]; then
            echo " Is that correct? [y/n]: y"
        else
            read -p " Is that correct? [y/n]: " answer
        fi
	    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ]|| [ "$2" = "-y" ]; then
		for daemon in "${activatingdaemons[@]}"; do 
		    ln -s /etc/sv/$daemon /var/service
		done
		echo " Successfully activated ${activatingdaemons} !"
	    fi
	else 
	    echo " No daemons to activate"
	fi

	echo ""
	#echo " Looking for daemons that must be removed..."
	echo ""

	activedaemons=$(ls /var/service | grep -v tty)
	original_activedaemons="$activedaemons"  

	for daemon in "${daemons[@]}"; do
	    activedaemons="$(echo "$activedaemons" | grep -vw "$daemon")"
	done

	if [ "$activedaemons" ]; then
	    echo " We are going to remove $(echo $activedaemons | paste -sd ' ' ) "
        if [ "$2" = "-y" ]; then
            echo " Is that correct? [y/n]: y"
        else
            read -p " Is that correct? [y/n]: " answer
        fi
	    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ]|| [ "$2" = "-y" ]; then
		activedaemonslist=($activedaemons)
		for daemon in ${activedaemonslist[@]}; do
		    rm -r /var/service/$daemon
		done
		echo " Successfully removed the next daemons: $(echo $activedaemons | paste -sd ' ' ) !"
	    else
		echo " The daemon $daemon does not exist"
		exit
	    fi
	else
	    echo " No daemons to remove."
	fi
elif [ "$1" = "back" ] || [ "$1" = "-b" ]; then
	ls /etc/voidec/backup/configuration
	read -p " Which one do you want to use? [full name]: " version
	if [ $(find /etc/voidec/backup/configuration -name $version) ]; then
		sleep 0
	else
		echo " The file does not exist. Aborting..."
		exit
	fi
	cp /etc/voidec/configuration.void /etc/voidec/backup/configuration/configuration.void_$(date +%Y-%m-%d-%H-%M-%S)
	cp /etc/voidec/backup/configuration/$version /etc/voidec/configuration.void
	read -p "Do you want to apply it? [Y/n]" answer
    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ]|| [ "$2" = "-y" ]; then
		bash /declarative.sh switch
	else
		exit
	fi
elif [ "$1" = "clean" ] || [ "$1" = "-c" ]; then
	read -p "Are you sure you want to delete all backups? [Y/n]: " answer
    if [ "$answer" = "Y" ] || [ "$answer" = "YES" ] || [ "$answer" = "Yes" ] || [ "$answer" = "y" ] || [ "$answer" = "yes" ]|| [ "$2" = "-y" ]; then
		rm -f /etc/voidec/backup/configuration/*
	else
		echo " Aborting..."
		exit
	fi
elif [ "$1" = "config" ] || [ "$1" = "-f" ]; then
    echo ""
    ls /etc/voidec/config
    echo ""
    read -p "Which one do you want to update? [directory names/all]: " config
    read -p "Which is your user? [user]: " user
    read -p "Do you want to create a backup of old versions [Y/n]: " answer
    if [ $answer = "n" ] || [ $answer = "no" ] || [ $answer = "No" ]; then
        sleep 0
    else
        configback="true"
    fi
    if [ "$config" = "all" ]; then
        config=$(ls /etc/voidec/config/)
    fi
    configs=($config)
    for directory in ${configs[@]}; do
        if [ "$configback" = "true" ]; then
            cp -r /home/$user/.config/$directory /etc/voidec/backup/config/"$directory"_"$(date +%Y-%m-%d-%H-%M-%S)"
        fi
        cp -r /etc/voidec/config/$directory /home/$user/.config/
    done
    echo "Successfully updated $config in /home/$user/.config/"
    exit
elif [ "$1" = "generate" ] || [ "$1" = "-g" ]; then
    while true; do 
        read -p "Are you sure you want to generate the configuration? This will overwrite anything in /etc/voidec. [y/n]: " answer
        if [ "$answer" = "y" ] || [ "$2" = "-y" ]; then
            mkdir /etc/voidec/
            echo "Generating /etc/voidec configurations..."
            packages=($(xbps-query -m |  sed 's/-[^-]*$//' ))
            echo "[PACKAGES]" > /etc/voidec/configuration.void 
            echo " " >> /etc/voidec/configuration.void
            for package in ${packages[@]}; do 
                echo "$package" >> /etc/voidec/configuration.void
            done
            echo " " >> /etc/voidec/configuration.void
            echo "[DAEMONS]" >> /etc/voidec/configuration.void
            echo " " >> /etc/voidec/configuration.void
            daemons=($(ls /var/service | grep -v "agetty" ))
            for daemon in ${daemons[@]}; do 
                echo "$daemon" >> /etc/voidec/configuration.void
            done
            mkdir /etc/voidec/backup
            mkdir /etc/voidec/config
            break
        elif [ "$answer" = "n" ]; then
            echo "Aborting..."
            break
        else
            echo " $answer is not a valid option. "
        fi
    done
else
	echo "Usage: voidec-rebuild [ARGUMENT] [OPTION]"
	echo "A tool used to declaratively install packages and manage daemons in Void Linux. "
	echo ""
    echo "Arguments:"
	echo "--help, -h:        Show this message."
	echo "switch, -s:        Rebuild the system using /etc/voidec/configuration.void, and backup the file."
	echo "back, -b:          Use a backup as configuration and replace latest file with this one."
	echo "clean, -c:         Delete all backups."
    echo "config, -f:        Replace packages configuration in .config with the config files in /etc/voidec/config, and save a backup" 
    echo "generate, -g:      Generate the configuration files based on current system status."
    echo ""
    echo "Options:"
    echo "-y                 Auto answer everything with 'yes'"
fi
