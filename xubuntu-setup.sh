#!/bin/bash

#########################################################################################
# Control codes for colored output
#########################################################################################

INFO=$(tput setaf 6)
ALERT=$(tput setaf 1)
HIGH=$(tput setaf 5)
NC=$(tput sgr0)

#########################################################################################
# System vars
#########################################################################################

UNAME=$(env | grep SUDO_USER | sed 's/.*=//')    # name of the sudo user
UGROUP=$(id -gn $UNAME)                          # name of the sudo group
CORES=$(nproc)                                   # number of physical cores

#########################################################################################
# Working paths
#########################################################################################

OPTDIR=/opt
HM=/home/$UNAME
WORKDIR=$(pwd)

#########################################################################################
# Repositories & soft list
#########################################################################################

JDK_VER="16"

APT_PACKAGES="binutils autoconf automake libtool checkinstall openssl libcurl4-openssl-dev libssl-dev libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
              libgtk2.0-dev libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libv4l-dev
              libtiff5-dev libdc1394-22-dev libatlas-base-dev gfortran ibus wmctrl tcl-dev tk-dev python-tk python3-tk libcupti-dev libglu1-mesa-dev libx11-dev libxmu-dev
              libxi-dev libgl1-mesa-glx libboost-all-dev libboost-python-dev freeglut3 freeglut3-dev python3-dev libxcb-xtest0
              build-essential openjdk-$JDK_VER-jdk ant maven vim
              htop pkg-config software-properties-gtk gdb m4
              python3-software-properties software-properties-common mesa-utils
              apt-transport-https ca-certificates mesa-utils-extra xserver-xorg-dev
              ssh nfs-kernel-server nfs-common seahorse unzip unrar keepass2
              postgresql postgresql-contrib pgadmin3 xdotool cmake
              python3-pip telegram-desktop virtualbox hardinfo snapd
              gnome-tweak-tool httpie bat
              google-chrome-stable sublime-text docker-ce
              gimp gimp-data gimp-plugin-registry gimp-data-extras
              libreoffice libreoffice-gtk3"

PURGE_SOFT="modemmanager pidgin catfish gnome-mines
            gnome-sudoku xfburn gigolo mousepad thunderbird
            sgt-launcher sgt-puzzles"

TOR_URL="https://dist.torproject.org/torbrowser/10.0.18/tor-browser-linux64-10.0.18_en-US.tar.xz"

#########################################################################################
# Routines
#########################################################################################

check_reboot() {
    echo
    if [ -f /var/run/reboot-required ]; then
        printf "${ALERT} - Reboot required. Halt.${NC}\n"
        exit 0
    fi;
}

update() {
    echo
    printf "${INFO} - Updating default packages:${NC}\n"
    echo

    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
    # curl is needed before the apt packages are installed
    apt-get install curl
    check_reboot
}

cleanup() {
    echo
    printf "${INFO} - Purging unnecessary packages:${NC}\n"
    echo

    apt-get purge $PURGE_SOFT -y
    apt-get autoremove -y
    apt-get autoclean -y
    check_reboot
}

add_repos() {
    echo
    printf "${INFO} - Adding custom repositories:${NC}\n"
    echo

    # Chrome repo
    if ! apt-cache policy | grep google > /dev/null; then
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        sh -c 'printf "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    else
        printf "${INFO}\tGoogle Chrome repo is already there${NC}\n"
    fi

    # Docker repo
    if ! apt-cache policy | grep docker > /dev/null; then
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" >> /etc/apt/sources.list.d/docker.list
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    else
        printf "${INFO}\tDocker repo is already there${NC}\n"
    fi 

    # Sublime repo
    if ! apt-cache policy | grep sublime > /dev/null; then
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
        apt-add-repository "deb https://download.sublimetext.com/ apt/stable/" --yes 
    else
        printf "${INFO}\tSublime Text repo is already there${NC}\n"
    fi

    # Nvidia repo
    if ! apt-cache policy | grep graphics > /dev/null; then
        apt-add-repository ppa:graphics-drivers/ppa --yes 
    else
        printf "${INFO}\tNvidia repo is already there${NC}\n"
    fi

    # gping repo
    if ! apt-cache policy | grep gping > /dev/null; then
        echo "deb http://packages.azlux.fr/debian/ buster main" | tee /etc/apt/sources.list.d/azlux.list
        wget -qO - https://azlux.fr/repo.gpg.key | apt-key add -
    else
        printf "${INFO}\tGping repo is already there${NC}\n"
    fi

    apt-get update
}

fetch_packages() {
    echo
    printf "${INFO} - Downloading additional packages:${NC}\n"
    echo

    if [[ ! -f "tor.tar.xz" ]]; then
        printf "${INFO}   - tor.tar.xz${NC}\n"
        curl -# -o tor.tar.xz https://dist.torproject.org/torbrowser/10.0.18/tor-browser-linux64-10.0.18_en-US.tar.xz
    fi

    if [[ ! -f "bottom.deb" ]]; then
        printf "${INFO}   - bottom.deb${NC}\n"
        curl -L -# -o bottom.deb https://github.com/ClementTsang/bottom/releases/download/0.6.2/bottom_0.6.2_amd64.deb
    fi

    if [[ ! -f "lsd.deb" ]]; then
        printf "${INFO}   - lsd.deb${NC}\n"
        curl -L -# -o lsd.deb https://github.com/Peltoche/lsd/releases/download/0.20.1/lsd_0.20.1_amd64.deb
    fi

    if [[ ! -f "hyperfine.deb" ]]; then
        printf "${INFO}   - hyperfine.deb${NC}\n"
        curl -L -# -o hyperfine.deb https://github.com/sharkdp/hyperfine/releases/download/v1.11.0/hyperfine_1.11.0_amd64.deb
    fi

    chown -R $UNAME:$UGROUP ./*
    chmod 755 ./*
}


install_apt() {
    printf "${INFO} - Installing libraries and soft from default repositories...${NC}\n"
    apt-get install $APT_PACKAGES -y
    # `classic` snap support
    ln -s /var/lib/snapd/snap /snap
}

install_customs() {
    echo
    printf "${INFO} - Installing software from archives:${NC}\n"
    echo

    # Custom NVM install
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | sudo -u $UNAME bash

    # Custom Tor Browser install
    arch=tor.tar.xz
    tar xf $arch -C $OPTDIR
    folder_name=$(tar tJf $arch | sed -e 's@/.*@@' | uniq)
    chown -R $UNAME:$UGROUP $OPTDIR/$folder_name
    cp $OPTDIR/$folder_name/start-tor-browser.desktop /usr/share/applications/
    chmod 744 /usr/share/applications/start-tor-browser.desktop
    sed -i 's|\"\$(dirname\s\"\$\*\")\"|'"$OPTDIR/$folder_name"'|g' /usr/share/applications/start-tor-browser.desktop

    dpkg -i bottom.deb lsd.deb hyperfine.deb
}

install_snaps() {
    echo
    tries=15
    to_install=1
    snap_available=0
    while [[ "$snap_available" = 0 ]]
    do
        tries=$tries-1
        if [[ $tries -le 0 ]]; then
            # reset the flag, don't install snap packages
            to_install=0
            break
        fi

        snap install core
        snap_code=$?

        if [[ $snap_code = 0 ]]; then
            snap_available=1
        else
            printf "${INFO} Waiting for the snap service to initialize...${NC}\n"
            sleep 5
        fi
    done

    if [[ $to_install -ne 0 ]]; then
        printf "${INFO} - Installing software from snap:${NC}\n"
        echo
        printf "${INFO}   - vscode${NC}\n"
        snap install --classic code
        printf "${INFO}   - telegram${NC}\n"
        snap install telegram-desktop
        printf "${INFO}   - skype${NC}\n"
        snap install skype
        printf "${INFO}   - postman${NC}\n"
        snap install postman
        printf "${INFO}   - gradle${NC}\n"
        snap install gradle --classic
        printf "${INFO}   - zoom${NC}\n"
        snap install zoom-client
        printf "${INFO}   - procs${NC}\n"
        snap install procs
    else
        printf "${ALERT} - Snap service is not available at the moment, please try to run the snap installation later by running 'sudo ./xubuntu-setup.sh --install_defaults'.${NC}\n"
    fi
}

configs() {
    echo
    printf "${INFO} - Setting up configs:${NC}\n"
    echo

    # Display line numbers in vim
    echo "set number" > ~/.vimrc

    # FS tweak for VSCode
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
    sysctl -p

    # Custom aliases
    if [[ ! $(cat $HM/.bashrc | grep 'custom aliases') ]]; then
        cat $WORKDIR/config/xubuntu/bashrc >> $HM/.bashrc
    fi

    # Git config
    cat $WORKDIR/config/gitconf > $HM/.gitconfig
    chown $UNAME:$UGROUP $HM/.gitconfig

    # Customized configs for desktop, keyboard, etc.
    cat $WORKDIR/config/gitconf > $HM/.gitconfig
    cat $WORKDIR/config/xubuntu/helpers.rc > $HM/.config/xfce4/helpers.rc
    cat $WORKDIR/config/xubuntu/keyboard-layout.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
    cat $WORKDIR/config/xubuntu/mimeapps.list > $HM/.config/mimeapps.list
    mkdir $HM/.config/xfce4/panel/
    cat $WORKDIR/config/xubuntu/whiskermenu-7.rc > $HM/.config/xfce4/panel/whiskermenu-7.rc
    cat $WORKDIR/config/xubuntu/xfce4-desktop.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
    cat $WORKDIR/config/xubuntu/xfce4-keyboard-shortcuts.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
    cat $WORKDIR/config/xubuntu/xfce4-panel.xml > $HM/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
    cat $WORKDIR/config/xubuntu/terminalrc > $HM/.config/xfce4/terminal/terminalrc
    TERMINAL_COLUMNS=$(tput cols)
    TERMINAL_LINES=$(tput lines)
    sed -i -E "s|MiscDefaultGeometry=([0-9]+)x([0-9]+)|MiscDefaultGeometry=${TERMINAL_COLUMNS}x${TERMINAL_LINES}|" $HM/.config/xfce4/terminal/terminalrc

    #Other configs
    mkdir -p $HM/.config/lsd
    cp $WORKDIR/config/lsd.config.yml $HM/.config/lsd/config.yml

    for i in "${WORKDIRS[@]}"; do
        if [[ ! -d $i ]]; then
            mkdir $i
            chown -R $UNAME:$UGROUP $i
        fi
    done

    chown -R $UNAME:$UGROUP $HM/.config

    #SSH config
    SSH_DIR=$HM/.ssh
    if [ -d "$SSH_DIR" ]; then
        # start the ssh-agent in the background
        eval $(ssh-agent -s)
        # make ssh agent to actually use copied key
        ssh-add $SSH_DIR/id_rsa
        chmod 700 $SSH_DIR
        chmod 600 $SSH_DIR/id_rsa
        chmod 600 $SSH_DIR/id_rsa.pub
        chmod 600 $SSH_DIR/config
    else
        printf "${ALERT} - SSH directory not found in the home directory. Did you forget to put it there? ${INFO}Continue:${NC}\n"
    fi
}


#########################################################################################
# Main
#########################################################################################

print_usage() {
    printf "Usage: sudo ./xubuntu-setup.sh [OPTION]\n\n"
    printf "Options:\n"
    printf "\t--all (or no options) - perform all tasks\n"
    printf "\t-c, --cleanup - purge unused packages\n"
    printf "\t-r, --repos - add 3rd party repositories\n"
    printf "\t-p, --install_from_pm - install software using standard package managers\n"
    printf "\t-s, --install_from_source - install software from sources\n"
    printf "The script must be run as root.\n"
}

if [[ $EUID -ne "0" ]]; then
    print_usage
    exit 1
fi

valid_args=("" "--all" "-c" "--cleanup" "-r" "--repos" "-p" "--install_from_pm" "-s" "--install_from_source")
if [[ ! " ${valid_args[@]} " =~ " $1 " ]]; then
    print_usage
    exit 1
fi

echo
hostnamectl

mkdir -p $HM/xubuntu-setup
chown -R $UNAME:$UGROUP $HM/xubuntu-setup
pushd $HM/xubuntu-setup/ > /dev/null

case "$1" in
    ""|"--all")
        update
        cleanup
        add_repos
        fetch_packages
        install_apt
        install_customs
        install_snaps
        configs;;
    "-c"|"--cleanup")
        cleanup;;
    "-r"|"--repos")
        add_repos;;
    "-p"|"--install_from_pm")
        install_apt
        install_snaps;;
    "-s"|"--install_from_source")
        install_customs;;
esac

popd > /dev/null

echo
printf "${INFO} Done!${NC}\n"
echo
