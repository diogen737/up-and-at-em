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

APT_PACKAGES="binutils autoconf automake libtool checkinstall openssl libcurl4-openssl-dev libssl-dev libavcodec-dev libavformat-dev
              libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libv4l-dev gfortran ibus
              wmctrl tcl-dev tk-dev libboost-all-dev python3-dev build-essential openjdk-$JDK_VER-jdk ant maven vim htop pkg-config
              software-properties-gtk gdb m4 python3-software-properties software-properties-common apt-transport-https ca-certificates
              ssh nfs-kernel-server nfs-common seahorse unzip unrar keepass2 postgresql postgresql-contrib pgadmin4 cmake python3-pip
              virtualbox hardinfo snapd gnome-tweak-tool httpie bat google-chrome-stable sublime-text docker-ce dconf-editor
              gnome-tweak-tool ubuntu-cleaner tlp indicator-multiload"

PURGE_SOFT="modemmanager pidgin catfish gnome-mines
            gnome-sudoku xfburn gigolo mousepad thunderbird
            sgt-launcher sgt-puzzles aisleriot gnome-mahjongg"

TOR_URL="https://dist.torproject.org/torbrowser/10.0.18/tor-browser-linux64-10.0.18_en-US.tar.xz"
BOTTOM_URL="https://github.com/ClementTsang/bottom/releases/download/0.6.2/bottom_0.6.2_amd64.deb"
LSD_URL="https://github.com/Peltoche/lsd/releases/download/0.20.1/lsd_0.20.1_amd64.deb"
HYPERFINE_URL="https://github.com/sharkdp/hyperfine/releases/download/v1.11.0/hyperfine_1.11.0_amd64.deb"

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
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
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

    # pgAdmin repo
    if ! apt-cache policy | grep pgadmin > /dev/null; then
        curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | apt-key add
	    sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
    else
	    printf "${INFO}\tpgAdmin repo is already there${NC}\n"
    fi

    # ubuntu-cleaner repo
    if ! apt-cache policy | grep gerardpuig > /dev/null; then
        add-apt-repository ppa:gerardpuig/ppa --yes
    else
	    printf "${INFO}\tubuntu-cleaner repo is already there${NC}\n"
    fi

    apt-get update
}

fetch_packages() {
    echo
    printf "${INFO} - Downloading additional packages:${NC}\n"
    echo

    if [[ ! -f "tor.tar.xz" ]]; then
        printf "${INFO}   - tor.tar.xz${NC}\n"
        curl -# -o tor.tar.xz $TOR_URL
    fi

    if [[ ! -f "bottom.deb" ]]; then
        printf "${INFO}   - bottom.deb${NC}\n"
        curl -L -# -o bottom.deb $BOTTOM_URL
    fi

    if [[ ! -f "lsd.deb" ]]; then
        printf "${INFO}   - lsd.deb${NC}\n"
        curl -L -# -o lsd.deb $LSD_URL
    fi

    if [[ ! -f "hyperfine.deb" ]]; then
        printf "${INFO}   - hyperfine.deb${NC}\n"
        curl -L -# -o hyperfine.deb $HYPERFINE_URL
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
    printf "${INFO} - Installing software from snap:${NC}\n"
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
        printf "${INFO}   - vscode (1/10)${NC}\n"
        snap install --classic code
        printf "${INFO}   - telegram (2/10)${NC}\n"
        snap install telegram-desktop
        printf "${INFO}   - skype (3/10)${NC}\n"
        snap install skype
        printf "${INFO}   - postman (4/10)${NC}\n"
        snap install postman
        printf "${INFO}   - gradle (5/10)${NC}\n"
        snap install gradle --classic
        printf "${INFO}   - zoom (6/10)${NC}\n"
        snap install zoom-client
        printf "${INFO}   - procs (7/10)${NC}\n"
        snap install procs
        printf "${INFO}   - gimp (8/10)${NC}\n"
        snap install gimp
        printf "${INFO}   - spotify (9/10)${NC}\n"
        snap install spotify
        printf "${INFO}   - vlc (10/10)${NC}\n"
        snap install vlc
    else
        printf "${ALERT} - Snap service is not available at the moment, please try to run the snap installation later by running 'sudo ./ubuntu-setup.sh --install_defaults'.${NC}\n"
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

    # Reduce SSD writes
    sed -i "s/\errors=\b/noatime,errors=/g" /etc/fstab

    # Custom aliases
    if [[ ! $(cat $HM/.bashrc | grep 'custom aliases') ]]; then
        cat $WORKDIR/config/ubuntu/bashrc >> $HM/.bashrc
    fi

    # Git config
    cat $WORKDIR/config/gitconf > $HM/.gitconfig
    chown $UNAME:$UGROUP $HM/.gitconfig

    #Other configs
    mkdir -p $HM/.config/lsd
    cp $WORKDIR/config/lsd.config.yml $HM/.config/lsd/config.yml
    cp $WORKDIR/config/ubuntu/indicator.multiload.preferences.ui /usr/share/indicator-multiload/preferences.ui
    # run indicator multiload manually for the first time
    nohup indicator-multiload &

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

    # Restore Gnome settings
    cp $WORKDIR/config/ubuntu/dconf.user $HM/.config/dconf/user
    chmod 644 $HM/.config/dconf/user
    chown $UNAME:$UGROUP $HM/.config/dconf/user
}


#########################################################################################
# Main
#########################################################################################

print_usage() {
    printf "Usage: sudo ./ubuntu-setup.sh [OPTION]\n\n"
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

mkdir -p $HM/ubuntu-setup
chown -R $UNAME:$UGROUP $HM/ubuntu-setup
pushd $HM/ubuntu-setup/ > /dev/null

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
