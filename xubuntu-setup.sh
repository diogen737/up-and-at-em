#!/bin/bash

#########################################################################################
#
# Control codes for colored output
#
#########################################################################################

INFO=$(tput setaf 6)
ALERT=$(tput setaf 1)
HIGH=$(tput setaf 5)
NC=$(tput sgr0)

#########################################################################################
#
# System vars
#
#########################################################################################

UNAME=$(env | grep SUDO_USER | sed 's/.*=//')    # name of the sudo user
UGROUP=$(id -gn $UNAME)                          # name of the sudo group
CORES=$(nproc)                                   # number of physical cores
SCREEN_WIDTH=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
SCREEN_HEIGHT=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2)
TERMINAL_COLUMNS=$(tput cols)
TERMINAL_LINES=$(tput lines)

#########################################################################################
#
# Some working paths
#
#########################################################################################

OPTDIR=/opt
HM=/home/$UNAME
MAKEDIR=./linux-distr
LOG=./setup.log

JUNKDIRS=( $HM/Videos $HM/Pictures $HM/Music $HM/Documents )
WORKDIRS=( $HM/sharespace $HM/dev $HM/dev/java $HM/dev/android
           $HM/dev/shell $HM/dev/python $HM/dev/web $HM/.npm-global $MAKEDIR  )

#########################################################################################
#
# Repositories & soft list
#
#########################################################################################

JDK_VER="14"

CORE="binutils autoconf automake libtool checkinstall openssl"

LIBS="libcurl4-openssl-dev libssl-dev libc6:i386 libncurses5:i386
      libstdc++6:i386 lib32z1 libbz2-1.0:i386 libgtk2.0-dev libgtk-3-dev
      libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev
      libx264-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libv4l-dev
      libtiff5-dev libdc1394-22-dev libatlas-base-dev gfortran ibus wmctrl
      tcl-dev tk-dev python-tk python3-tk libcupti-dev libglu1-mesa-dev
      libx11-dev libxmu-dev libxi-dev libgl1-mesa-glx libboost-all-dev
      libboost-python-dev freeglut3 freeglut3-dev python3-dev libxcb-xtest0"

DEV="build-essential openjdk-$JDK_VER-jdk ant maven vim"

UTILS="htop pkg-config software-properties-gtk gdb m4
       python3-software-properties software-properties-common mesa-utils 
       apt-transport-https ca-certificates mesa-utils-extra xserver-xorg-dev
       ssh curl nfs-kernel-server nfs-common seahorse unzip unrar keepass2
       postgresql postgresql-contrib pgadmin3 xdotool cmake
       python-pip python3-pip telegram-desktop virtualbox"

CUSTOM_SOFT="git google-chrome-stable sublime-text docker-ce
             gimp gimp-data gimp-plugin-registry gimp-data-extras
             libreoffice libreoffice-gtk3 code nodejs"

PURGE_SOFT="modemmanager pidgin catfish gnome-mines
            gnome-sudoku xfburn gigolo mousepad thunderbird
            sgt-launcher sgt-puzzles" 

#########################################################################################
#
# Soft which benefits from manual installation
#
#########################################################################################

SOURCE_SOFT=( gradle skype postman npm tor zoom )

GRADLE_URL="https://downloads.gradle-dn.com/distributions/gradle-6.0.1-all.zip"
SKYPE_URL="https://repo.skype.com/latest/skypeforlinux-64.deb"
POSTMAN_URL="https://dl.pstmn.io/download/latest/linux64"
TOR_URL="https://dist.torproject.org/torbrowser/9.0.2/tor-browser-linux64-9.0.2_en-US.tar.xz"
ZOOM_URL="https://d11yldzmag5yn.cloudfront.net/prod/3.5.336627.1216/zoom_amd64.deb"

#########################################################################################
#
# Check if the system needs reboot
#
#########################################################################################

check_reboot() {
    printf "\n" 
    if [ -f /var/run/reboot-required ]; then
        printf "${ALERT} - Reboot required. Halt.${NC}\n"
        exit 0
    fi;
}

#########################################################################################
#
# Run command with one line output
#
#########################################################################################

run-one-line() {
    $1 | while IFS= read -r line
    do
        echo -ne "\r\033[K\t${line:0:$TERMINAL_COLUMNS}"
    done
    return ${PIPESTATUS[0]}
}

#########################################################################################
#
# Purge unnecessary packages
#
#########################################################################################

cleanup() {
    printf "${INFO} - Purging unnecessary packages...${NC}\n"
    update_index
    run-one-line "apt-get purge $PURGE_SOFT -y"

    run-one-line "apt-get autoremove -y"
    run-one-line "apt-get autoclean -y"
    check_reboot
}

#########################################################################################
#
# Upgrade the system to the latest state
#
#########################################################################################

update_index() {
    printf "${INFO}\tUpdating cache... ${NC}"
    apt-get update > /dev/null
    printf "${INFO}Done${NC}\n"
}

upgrade() {
    printf "${INFO} - Upgrading default packages...${NC}\n"
    update_index
    run-one-line "apt-get dist-upgrade -y"
    check_reboot
}

#########################################################################################
#
# Install required libraries, utilities and software from default repositories
#
#########################################################################################

install_defaults() {
    printf "${INFO} - Installing libraries and soft from default repositories... ${NC}\n"
    update_index
    run-one-line "apt-get install $CORE $LIBS $DEV $UTILS -y"
    check_reboot
}

#########################################################################################
#
# Install some additional repositories
#
#########################################################################################

add_repos() {
    printf "${INFO} - Setting up 3rd party repositories...${NC}\n"
    update_index

    ######################################################################
    # CHROME REPO
    ######################################################################
    if ! apt-cache policy | grep google > /dev/null; then
        printf "${INFO}\tAdding Google Chrome repo... ${NC}"
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - >> $LOG 2>&1
        sh -c 'printf "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' >> $LOG 2>&1
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tGoogle Chrome repo is already there${NC}\n"
    fi

    ######################################################################
    # NODE REPO
    ######################################################################
    if ! apt-cache policy | grep node > /dev/null; then
        printf "${INFO}\tAdding NodeJS repo... ${NC}"
        curl -sL https://deb.nodesource.com/setup_11.x -o nodesource_setup.sh
        bash nodesource_setup.sh >> $LOG 2>&1
        rm nodesource_setup.sh
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tNodeJS repo is already there${NC}\n"
    fi

    ######################################################################
    # VS CODE REPO
    ######################################################################
    if ! apt-cache policy | grep vscode > /dev/null; then
        printf "${INFO}\tAdding VS Code repo... ${NC}"
        curl -sL https://packages.microsoft.com/keys/microsoft.asc | sudo -H gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg
        sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' >> $LOG 2>&1
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tVS Code repo is already there${NC}\n"
    fi

    ######################################################################
    # DOCKER REPO
    ######################################################################
    if ! apt-cache policy | grep docker > /dev/null; then
        printf "${INFO}\tAdding Docker repo... ${NC}"
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" >> /etc/apt/sources.list.d/docker.list
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> $LOG 2>&1
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tDocker repo is already there${NC}\n"
    fi 

    ######################################################################
    # SUBLIME REPO
    ######################################################################
    if ! apt-cache policy | grep sublime > /dev/null; then
        printf "${INFO}\tAdding Sublime Text repo... ${NC}"
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add - >> $LOG 2>&1
        apt-add-repository "deb https://download.sublimetext.com/ apt/stable/" --yes >> $LOG 2>&1 
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tSublime Text repo is already there${NC}\n"
    fi

    ######################################################################
    # NVIDIA REPO
    ######################################################################
    if ! apt-cache policy | grep graphics > /dev/null; then
        printf "${INFO}\tAdding Nvidia repo... ${NC}"
        apt-add-repository ppa:graphics-drivers/ppa --yes >> $LOG 2>&1 
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tNvidia repo is already there${NC}\n"
    fi

    ######################################################################
    # GIT REPO
    ######################################################################
    if ! apt-cache policy | grep git-core > /dev/null; then
        printf "${INFO}\tAdding Git repo... ${NC}"
        apt-add-repository ppa:git-core/ppa --yes >> $LOG 2>&1 
        printf "${INFO}Done${NC}\n"
    else
        printf "${INFO}\tGit repo is already there${NC}\n"
    fi     

    update_index
}

#########################################################################################
#
# Install required libraries, utilities and software from custom repositories
#
#########################################################################################

install_customs() {
    printf "${INFO} - Installing soft from custom repositories... ${NC}\n"
    update_index
    run-one-line "apt-get install $CUSTOM_SOFT -y"

    check_reboot
}

#########################################################################################
#
# Install nvidia graphics drivers
# Out of use because binary distribution installation on init 3 level is more reliable
# (Didn't delete this code jus because I like it)
#
#########################################################################################

# install_nvidia() {
#     if ! dpkg -l | grep nvidia > /dev/null; then
# 	    read -p "Do you want to install NVIDIA drivers? " -n 1 -r
# 	    echo
#     	if [[ $REPLY =~ ^[Yy]$ ]]
#     	then	
# 	    	printf "${INFO} - Installing graphics drivers...${NC}\n"
# 	        printf "${INFO}\tAvailable driver versions:\n"
# 	        printf "========================\n"
# 	        apt-cache search ^nvidia-[0-9] | grep -vE 'dev|updates|headless|uvm'
# 	        printf "========================${NC}"
# 	        RC=1
# 	        ERR_MSG=""
# 	        while [ $RC -ne 0 ]; do
# 	            echo -e $ERR_MSG
# 	            printf "${INFO}\tPick a version: ${NC}"
# 	            read ver
# 	            run-one-line "apt-get install nvidia-$ver nvidia-settings -y"
# 	            RC=$?
# 	            ERR_MSG="${ALERT}\r\033[K\tWrong driver version${NC}"
# 	        done
# 	        printf "${INFO}\tInstallation complete. Configuring...${NC}\n"
# 	        nvidia-xconfig >> $LOG 2>&1
# 	        touch /var/run/reboot-required # just to be sure because we need reboot
# 	        check_reboot
#     	fi
#     else
#         printf "${INFO}\tThe driver is already installed${NC}\n"
#     fi
# }

#########################################################################################
#
# Install soft from source destribution (extract & run)
#
#########################################################################################

install_gradle() {
    if [ ! $(ls $OPTDIR | grep 'gradle') ]; then
        arch=gradle.zip
        printf "${INFO}\tDownloading... ${NC}\n"
        curl -# -o $arch $GRADLE_URL
        printf "${INFO}\tInstalling... ${NC}\n"

        unzip -qq -d $OPTDIR $arch
        gradle_root=$(unzip -qql $arch | sed -r '1 {s/([ ]+[^ ]+){3}\s+//;q}')
        chown -R $UNAME:$UGROUP $OPTDIR/$gradle_root
        echo 'export PATH="$PATH:/opt/'$gradle_root'bin"' >> $HM/.profile
        source $HM/.profile    

        rm $arch
    else
        printf "${INFO}\tGradle is in place...${NC}\n"
    fi
}

install_skype() {
    if [ -z $(which skypeforlinux) ]; then 
        arch=skype.deb

        printf "${INFO}\tDownloading... ${NC}\n"
        curl -# -o $arch $SKYPE_URL
        printf "${INFO}\tInstalling... ${NC}\n"
        dpkg -i $arch >> $LOG 2>&1

        rm $arch
    else
        printf "${INFO}\tSkype is in place...${NC}\n"
    fi
}

install_postman() {
    if [ ! $(ls $OPTDIR | grep 'Postman') ]; then 
        arch=postman.tar.gz
        
        printf "${INFO}\tDownloading... ${NC}\n"
        curl -# -o $arch $POSTMAN_URL
        printf "${INFO}\tInstalling... ${NC}\n"
        tar xf $arch -C $OPTDIR
        chown -R $UNAME:$UGROUP $OPTDIR/$(tar tzf $arch | sed -e 's@/.*@@' | uniq)
      
        echo "[Desktop Entry]" > /usr/share/applications/postman.desktop
        echo "  Name=Postman" >> /usr/share/applications/postman.desktop
        echo "  Type=Application" >> /usr/share/applications/postman.desktop
        echo "  Exec=/opt/Postman/Postman" >> /usr/share/applications/postman.desktop
        echo "  Terminal=false" >> /usr/share/applications/postman.desktop
        echo "  Icon=/opt/Postman/app/resources/app/assets/icon.png" >> /usr/share/applications/postman.desktop
        echo "  Comment=" >> /usr/share/applications/postman.desktop
        echo "  NoDisplay=false" >> /usr/share/applications/postman.desktop
        echo "  Categories=Development;" >> /usr/share/applications/postman.desktop

        rm $arch
    else
        printf "${INFO}\tPostman is in place...${NC}\n"
    fi
}

install_tor() {
    if [ ! $(ls $OPTDIR | grep 'tor-browser') ]; then 
        arch=tor_browser.tar.xz
        
        printf "${INFO}\tDownloading... ${NC}\n"
        curl -# -o $arch $TOR_URL
        printf "${INFO}\tInstalling... ${NC}\n"
        tar xf $arch -C $OPTDIR
        folder_name=$(tar tJf $arch | sed -e 's@/.*@@' | uniq)
        chown -R $UNAME:$UGROUP $OPTDIR/$folder_name

        cp $OPTDIR/$folder_name/start-tor-browser.desktop /usr/share/applications/
        chmod 744 /usr/share/applications/start-tor-browser.desktop
        sed -i 's|\"\$(dirname\s\"\$\*\")\"|'"$OPTDIR/$folder_name"'|g' /usr/share/applications/start-tor-browser.desktop

        rm $arch
    else
        printf "${INFO}\tTor Browser is in place...${NC}\n"
    fi
}

install_zoom() {
    if [ -z $(which zoom) ]; then 
        arch=zoom.deb

        printf "${INFO}\tDownloading... ${NC}\n"
        curl -# -o $arch $ZOOM_URL
        printf "${INFO}\tInstalling... ${NC}\n"
        dpkg -i $arch >> $LOG 2>&1

        rm $arch
    else
        printf "${INFO}\Zoom is in place...${NC}\n"
    fi
}

install_npm() {
    npm i -g npm >> $LOG 2>&1
}

#########################################################################################
#
# Main routine for installations above
#
#########################################################################################

install_archives() {
    archs=("$@")
    for name in "${archs[@]}"; do
        printf "${INFO} - Setting up $name...${NC}\n"
        install_$name
        printf "${INFO}\tDone${NC}\n"
    done   
}

#########################################################################################
#
# Setup different config files for git, xfce etc.
#
#########################################################################################

configs() {

    printf "${INFO} - Setting up config files...${NC}\n"

    sed -i 's|# en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /etc/locale.gen
    sed -i 's|# ru_RU.UTF-8 UTF-8|ru_RU.UTF-8 UTF-8|' /etc/locale.gen
    locale-gen
    localectl set-locale LANG=en_US.utf8
    update-locale LC_ALL=en_US.UTF-8

    # Display line numbers in vim
    echo "set number" > ~/.vimrc

    # Workaround for VS Code
    echo "fs.inotify.max_user_watches=524288" > /etc/sysctl.conf
    sysctl -p

    # Custom aliases
    if [[ ! $(cat $HM/.bashrc | grep 'custom aliases') ]]; then
        cat ./config/bashrc >> $HM/.bashrc
    fi

    # Customized configs for desktop, keyboard, etc.
    cat ./config/gitconf > $HM/.gitconfig
    cat ./config/helpers.rc > $HM/.config/xfce4/helpers.rc
    cat ./config/keyboard-layout.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
    cat ./config/mimeapps.list > $HM/.config/mimeapps.list
    mkdir $HM/.config/xfce4/panel/
    cat ./config/whiskermenu-7.rc > $HM/.config/xfce4/panel/whiskermenu-7.rc
    cat ./config/xfce4-desktop.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
    cat ./config/xfce4-keyboard-shortcuts.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
    cat ./config/xfce4-panel.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
    cat ./config/terminalrc > $HM/.config/xfce4/terminal/terminalrc
    sed -i -E "s|MiscDefaultGeometry=([0-9]+)x([0-9]+)|MiscDefaultGeometry=${TERMINAL_COLUMNS}x${TERMINAL_LINES}|" $HM/.config/xfce4/terminal/terminalrc

    printf "${INFO} - Setting up directories...${NC}\n"

    for i in "${JUNKDIRS[@]}"; do 
        rm -rf $i
    done

    for i in "${WORKDIRS[@]}"; do
        if [[ ! -d $i ]]; then
            mkdir $i
            chown -R $UNAME:$UGROUP $i
            chmod -R 775 $i
        fi
    done

    printf "${INFO}   Done${NC}"
}


#########################################################################################
# 
# Main routine 
#
#########################################################################################


if [[ $EUID -ne "0" ]]; then
    printf "${ALERT}The script must be run as root. Abort. ${NC}\n"
    exit 1
fi

if [[ $(lsb_release -i) =~ "Distributor ID: Ubuntu" ]]; then
    printf "${ALERT}This script is for Ubuntu systems only. Abort. ${NC}\n"
    exit 1
fi

printf "${INFO}========================\n"
printf "Ubuntu system:\n"
printf "\t$(lsb_release -i)\n\t$(lsb_release -d)\n\t$(lsb_release -r)\n\t$(lsb_release -c)\n"
printf "========================\n"

case "$1" in
    ""|"--all")
        # Set Ubuntu packages source from main server
        sed -i 's|http://us.|http://|g' /etc/apt/sources.list
        sed -i 's|http://ru.|http://|g' /etc/apt/sources.list
        # Launch procedures 
        cleanup
        upgrade
        install_defaults
        add_repos
        install_customs
        upgrade
        install_archives "${SOURCE_SOFT[@]}"
        configs
        # Ensure we go to reboot
        touch /var/run/reboot-required
        check_reboot;;
    "--cleanup")
        cleanup;;
    "--repos")
        add_repos;;
    "--defaults")
        install_defaults;;
    "--custom")
        install_customs;;
    "--config")
        configs;;
    *)
        printf "${ALERT}Usage: xubuntu-setup [--all | --cleanup | --repos | --defaults | --custom | --config]\n"
        printf "Running with no arguments is equal to --all. The script must be run as root. ${NC}\n";;
esac

# Restore access to local config store

chown -R $UNAME:$UGROUP $HM/.config
