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
sudo init 3
sudo ./cuda_<version>_linux.run --override
echo 'PATH="$PATH:/usr/local/cuda-<version>/bin"' >> ~/.profile
echo 'LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-<version>/lib64"' >> ~/.profile
# reboot
cd ~/NVIDIA_CUDA-<version>_Samples
make all -j5
./1_Utilities/deviceQuery/deviceQuery # to check CUDA installation
```

 - Python virtual environment installation
  
```
pip install pipenv
```

 - dlib from source

```bash
workon neuro
git clone https://github.com/davisking/dlib.git
cd dlib
git checkout <the latest version>
python setup.py install --yes USE_AVX_INSTRUCTIONS
```

 - OpenCV from source

```bash
workon neuro
wget -O opencv.zip https://github.com/Itseez/opencv/archive/3.4.0.zip
wget -O opencv_contrib.zip https://github.com/Itseez/opencv_contrib/archive/3.4.0.zip
unzip -d ~/linux-distr opencv.zip
unzip -d ~/linux-distr opencv_contrib.zip
mkdir ~/linux-distr/opencv-3.4.0/build
cd ~/linux-distr/opencv-3.4.0/build
cmake -D build_type=release -D cmake_install_prefix=/usr/local \
      -D install_python_examples=on -D install_c_examples=off \
      -D install_java_examples=on -D with_cuda=on \
      -D opencv_extra_modules_path=~/linux-distr/opencv_contrib-3.4.0/modules \
      -D python_executable=~/.virtualenvs/neuro/bin/python3.6 \
      -D build_examples=on ..
make all -j4 && sudo make install -j4
sudo ldconfig
sudo mv /usr/local/lib/python3.6/site-packages/cv2.cpython-36m-x86_64-linux-gnu.so /usr/local/lib/python3.6/site-packages/cv2.so
ln -s /usr/local/lib/python3.6/site-packages/cv2.cpython-36m-x86_64-linux-gnu.so ~/.virtualenvs/neuro/lib/python3.6/site-packages/cv2.so
```

### Additional setup steps
 - Arrange Favorites in the Whisker menu
 - Add System load, Workspace switcher panels on the system panel
 - Setup keyboard shortcuts
