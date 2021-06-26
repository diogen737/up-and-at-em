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
# Routines
#########################################################################################

update() {
    echo
    printf "${INFO} - Updating default packages: ${NC}\n"
    echo
    dnf update -y
}

add_repos() {
    echo
    printf "${INFO} - Adding custom repositories: ${NC}\n"
    echo

    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf copr enable atim/bottom -y
    dnf copr enable atim/gping -y
}

fetch_packages() {
    echo
    printf "${INFO} - Downloading additional packages: ${NC}\n"
    echo

    if [[ ! -f "google-chrome.rpm" ]]; then
        printf "${INFO}   - google-chrome.rpm${NC}\n"
        curl -# -o google-chrome.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    fi
    if [[ ! -f "virtualbox.rpm" ]]; then
        printf "${INFO}   - virtualbox.rpm${NC}\n"
        curl -# -o virtualbox.rpm https://download.virtualbox.org/virtualbox/6.1.22/VirtualBox-6.1-6.1.22_144080_fedora33-1.x86_64.rpm
    fi
    if [[ ! -f "zoom.rpm" ]]; then
        printf "${INFO}   - zoom.rpm${NC}\n"
        curl -# -o zoom.rpm https://cdn.zoom.us/prod/5.6.22045.0607/zoom_x86_64.rpm
    fi
    if [[ ! -f "gradle.zip" ]]; then
        printf "${INFO}   - gradle.zip${NC}\n"
        curl -# -o gradle.zip https://downloads.gradle-dn.com/distributions/gradle-7.0.2-all.zip
    fi
    if [[ ! -f "tor.tar.xz" ]]; then
        printf "${INFO}   - tor.tar.xz${NC}\n"
        curl -# -o tor.tar.xz https://dist.torproject.org/torbrowser/10.0.17/tor-browser-linux64-10.0.17_en-US.tar.xz
    fi
    chown -R $UNAME:$UGROUP ./*
}

install_dnf() {
    echo
    printf "${INFO} - Installing software from repositories: ${NC}\n"
    echo
    dnf install -y @development-tools snapd binutils dconf dconf-editor autoconf automake libtool openssl gfortran ibus \
        wmctrl ant maven vim make automake gcc g++ kernel-devel htop gdb unzip postgresql postgresql-contrib pgadmin3 cmake \
        dnf-plugins-core sublime-text docker-ce docker-ce-cli containerd.io keepass gnome-tweak-tool lsd bottom hyperfine \
        gping procs httpie bat \
        ./google-chrome.rpm ./virtualbox.rpm ./zoom.rpm
    # `classic` snap support
    ln -s /var/lib/snapd/snap /snap
}

install_snaps() {
    echo
    tries=20
    to_install=1
    while systemctl is-active --quiet snapd.seeded.service
    do
        printf "${INFO} Waiting for the snap seed service to terminate...${NC}\n"

        sleep 5
        tries=$tries-1

        if [[ $tries -le 0 ]]; then
            # reset the flag, don't install snap packages
            to_install=0
            break
        fi
    done

    if [[ $to_install -ne 0 ]]; then
        printf "${INFO} - Installing software from snap: ${NC}\n"
        echo
        printf "${INFO}   - snap core${NC}\n"
        snap install core
        printf "${INFO}   - vscode${NC}\n"
        snap install --classic code
        printf "${INFO}   - telegram${NC}\n"
        snap install telegram-desktop
        printf "${INFO}   - skype${NC}\n"
        snap install skype
        printf "${INFO}   - postman${NC}\n"
        snap install postman
    else
        printf "${ALERT} - Snap seed service is still running, please try to run the snap installation later by running 'sudo ./fedora-setup.sh --install_defaults'. ${NC}\n"
    fi
}

install_customs() {
    echo
    printf "${INFO} - Installing software from archives: ${NC}\n"
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

    # Custom Gradle install
    arch=gradle.zip
    unzip -qq -d $OPTDIR $arch
    gradle_root=$(unzip -qql $arch | sed -r '1 {s/([ ]+[^ ]+){3}\s+//;q}')
    chown -R $UNAME:$UGROUP $OPTDIR/$gradle_root
    echo 'export PATH="$PATH:/opt/'$gradle_root'bin"' >> $HM/.bashrc
    source $HM/.bashrc
}

configs() {
    echo
    printf "${INFO} - Setting up configs: ${NC}\n"
    echo

    # Display line numbers in vim
    echo "set number" > ~/.vimrc

    # FS tweak for VSCode
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
    sysctl -p

    # Custom aliases
    if [[ ! $(cat $HM/.bashrc | grep 'custom aliases') ]]; then
        cat $WORKDIR/config/fedora/bashrc >> $HM/.bashrc
    fi

    # Git config
    cat $WORKDIR/config/gitconf > $HM/.gitconfig
    chown $UNAME:$UGROUP $HM/.gitconfig

    # Restore Gnome settings
    cp $WORKDIR/config/fedora/dconf.user $HM/.config/dconf/user
    chmod 644 $HM/.config/dconf/user
    chown $UNAME:$UGROUP $HM/.config/dconf/user

    #Other configs
    mkdir -p $HM/.config/lsd
    cp $WORKDIR/config/fedora/lsd.config.yml $HM/.config/lsd/config.yml

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
        printf "${ALERT} - SSH directory not found in the home directory. Did you forget to put it there? ${INFO}Continue: ${NC}\n"
    fi
}

#########################################################################################
# Main
#########################################################################################

print_usage() {
    printf "Usage: sudo ./fedora-setup.sh [OPTION]\n\n"
    printf "Options:\n"
    printf "\t--all (or no options) - perform all tasks\n"
    printf "\t-r, --repos - add 3rd party repositories\n"
    printf "\t-p, --install_from_pm - install software using standard package managers\n"
    printf "\t-s, --install_from_source - install software from sources\n"
    printf "The script must be run as root.\n"
}

if [[ $EUID -ne "0" ]]; then
    print_usage
    exit 1
fi

valid_args=("" "--all" "-r" "--repos" "-p" "--install_from_pm" "-s" "--install_from_source")
if [[ ! " ${valid_args[@]} " =~ " $1 " ]]; then
    print_usage
    exit 1
fi

echo
hostnamectl

mkdir -p $HM/fedora-setup
chown -R $UNAME:$UGROUP $HM/fedora-setup
pushd $HM/fedora-setup/ > /dev/null

case "$1" in
    ""|"--all")
        update
        add_repos
        fetch_packages
        install_dnf
        install_customs
        install_snaps
        configs;;
    "-r"|"--repos")
        add_repos;;
    "-p"|"--install_from_pm")
        install_dnf
        install_snaps;;
    "-s"|"--install_from_source")
        install_customs;;
esac

popd > /dev/null
