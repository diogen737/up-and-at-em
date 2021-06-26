<h1 style="text-align: center">up-and-at-em</h1>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

My personal setup scripts for various linux distributions which do the following:

- Purge unused packages
- Upgrade the system to the latest state
- Add 3rd party repositories
- Install necessary libs, utils and software from remote repositories
- Install additional software from source code (archives are downloaded during the script's work)
- Set up some config files (aliases in .bashrc, desktop shortcuts etc.)

## Usage

```bash
sudo ./xubuntu-setup.sh [OPTION]
sudo ./fedora-setup.sh [OPTION]
```

Options:

- --all (or no options) - perform all tasks
- -c, --cleanup (xubuntu only) - purge unused packages
- -r, --repos - add 3rd party repositories
- -p, --install_from_pm - install software using standard package managers
- -s, --install_from_source - install software from sources
