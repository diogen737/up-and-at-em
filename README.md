## Xubuntu initial setup

  This bash script serves as basic startup script that should be run right after fresh Xubuntu 18.04 installation. It performs following actions:
 - Purging redundant packages
 - Upgrading the system to the latest state
 - Adding 3rd party repositories 
 - Installing necessary libs, utils and software from remote repositories
 - Installing some software from source code (archives are downloaded during the script's work)
 - Setting up some config files (aliases in .bashrc, desktop shortcuts etc.)

**Warning!!! This script works only with 18.04LTS version of Xubuntu**

****

### Additional setups
  Here's a list of software and instructions for manual installation:

- Setup passwordless ssh connection:

```bash
ssh-keygen -t rsa -N ""
ssh-copy-id mk1 # hostname of your other machine goes here
sudo /etc/init.d/ssh restart
ssh-agent bash
ssh-add ~/.ssh/id_rsa
```
- Nvidia CUDA

```bash
# download cuda_<version>_linux.run
sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
echo 'export PATH="$PATH:/usr/local/cuda-<version>/bin"' >> ~/.profile
echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-<version>/lib64"' >> ~/.profile
sudo update-initramfs -u
# reboot
sudo init 3
sudo ./cuda_<version>_linux.run
# reboot
cd ~/NVIDIA_CUDA-<version>_Samples
make all -j5
./1_Utilities/deviceQuery/deviceQuery # to check CUDA installation
```

 - Python virtual environment installation
  
```
pip install pipenv
```
 - VS Code setup:
   - Install `Settings Sync` extension
   - Inport previously saved settings (keep Access token and Gist ID in private storage)


### Additional setup steps
 - Arrange Favorites in the Whisker menu:
   - LibreOffice Writer
   - LibreOffice Calc
   - MATE Calculator
   - Google Chrome
   - Firefox Web Browser
   - Tor Browser
   - Postman
   - Keepass
   - Skype
 - Add System load, Workspace switcher panels on the system panel
 - Setup desctop icons
 - Setup keyboard layout and shortcuts:
   - exo-open --launch FileManager `Super+E`
   - exo-open --launch TerminalEmulator `Super+T`
   - /usr/bin/guake `Super+R`
   - code `Super+C`
