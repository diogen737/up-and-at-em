# Xubuntu initial setup

This script provides different setup routines usually executed on a newly installed ubuntu system. It performs following actions:

- Purging redundant packages
- Upgrading the system to the latest state
- Adding 3rd party repositories
- Installing necessary libs, utils and software from remote repositories
- Installing additional software from source code (archives are downloaded during the script's work)
- Setting up some config files (aliases in .bashrc, desktop shortcuts etc.)

**Warning!!! This script has been tested on Xubuntu 19.10. Compatibility with other versions or distributions is not guaranteed.**

****

## Usage

- Download/clone the repo (f.e. I keep it on my Xubuntu USB stick)
- Run main script with `sudo` privileges (don't worry, it does no harm :wink:)

```bash
sudo ./xubuntu-setup.sh
  --all
  --cleanup
  --repos
  --defaults
  --custom
  --skype
  --postman
  --gradle
  --libinput
  --tor
  --config
```

## Additional setups

This script is fully automatic. There's some stuff that I could not implement though (or it's not absolutely necessary on my every system). Here's some extra config/installtion steps (it's more of a reminder for me than guide for you :smile:):

- Setup passwordless ssh connection:

```bash
ssh-keygen -t rsa -N ""
ssh-copy-id mk1 # hostname of your other machine goes here
sudo /etc/init.d/ssh restart
ssh-agent bash
ssh-add ~/.ssh/id_rsa
```

- Nvidia drivers (ppa is added during scrips's execution):
  
```bash
sudo sh -c "cat > /etc/modprobe.d/nvidia-graphics-drivers.conf << EOM
blacklist nouveau
blacklist lbm-nouveau
alias nouveau off
alias lbm-nouveau off
EOM"
sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT)(.*)\"$/\1\2 nomodeset\"/" /etc/default/grub
sudo update-grub

# reboot now

sudo init 3
sudo apt-get install nvidia-driver-<latest-version>

# reboot now
```

- Nvidia CUDA

```bash
# download cuda_<version>_linux.run
echo 'export PATH="$PATH:/usr/local/cuda-<version>/bin"' >> ~/.profile
echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-<version>/lib64"' >> ~/.profile
sudo update-initramfs -u

# reboot now

sudo init 3
sudo ./cuda_<version>_linux.run

# reboot now

cd ~/NVIDIA_CUDA-<version>_Samples
make all -j5
./1_Utilities/deviceQuery/deviceQuery # to check CUDA installation
```

- VS Code setup:
  - Install `Settings Sync` extension
  - Import previously saved settings (keep Access token and Gist ID in private storage)
