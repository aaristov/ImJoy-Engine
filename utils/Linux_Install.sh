#!/usr/bin/env bash
set -e

# Name of application to install
AppName="ImJoyEngine"

# Set your project's install directory name here
InstallDir="$HOME/ImJoyApp"

# Dependencies installed by Conda
# Comment out the next line if no Conda dependencies
CondaDeps="numpy scipy git"

# Install the package from PyPi
# Comment out next line if installing locally
PyPiPackage="git+https://github.com/oeway/ImJoy-Engine#egg=imjoy"

# Local packages to install
# Useful if your application is not in PyPi
# Distribute this with a .tar.gz and use this variable
# Comment out the next line if no local package to install
# LocalPackage="mypackage.tar.gz"

# Entry points to add to the path
# Comment out the next line of no entry point
#   (Though not sure why this script would be useful otherwise)
EntryPoint=""

echo
echo "Installing $AppName"

echo
echo "Installing into: $InstallDir"
echo

# Miniconda doesn't work for directory structures with spaces
if [[ $InstallDir == *" "* ]]
then
    echo "ERROR: Cannot install into a directory with a space in its path" >&2
    echo "Exiting..."
    echo
    exit 1
fi

# Test if new directory is empty.  Exit if it's not
if [ -d $InstallDir ]; then
    if [ "$(ls -A $InstallDir)" ]; then
        echo "ERROR: Directory is not empty" >&2
        echo "If you want to install into $InstallDir, "
        echo "clear the directory first and run this script again."
        echo "Exiting..."
        echo
        exit 1
    fi
else
    mkdir $InstallDir
fi

# Download and install Miniconda
set +e
curl "https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" -o $InstallDir/Miniconda_Install.sh
if [ $? -ne 0 ]; then
    curl "http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" -o $InstallDir/Miniconda_Install.sh
fi
set -e

bash $InstallDir/Miniconda_Install.sh -b -f -p $InstallDir

# Activate the new environment
PATH="$InstallDir/bin":$PATH

# Make the new python environment completely independent
# Modify the site.py file so that USER_SITE is not imported
python -s << END
import site
site_file = site.__file__.replace(".pyc", ".py");
with open(site_file) as fin:
    lines = fin.readlines();
for i,line in enumerate(lines):
    if(line.find("ENABLE_USER_SITE = None") > -1):
        user_site_line = i;
        break;
lines[user_site_line] = "ENABLE_USER_SITE = False\n"
with open(site_file,'w') as fout:
    fout.writelines(lines)
END

# Upgrade pip and conda
pip install pip --upgrade
conda update conda --yes --prefix=$InstallDir

# Install Conda Dependencies
if [[ $CondaDeps ]]; then
    conda install $CondaDeps --yes --prefix=$InstallDir
fi

# Install Package from PyPi
if [[ $PyPiPackage ]]; then
    pip install $PyPiPackage -q
fi

# Install Local Package
if [[ $LocalPackage ]]; then
    pip install $LocalPackage -q
fi

# Cleanup
rm $InstallDir/Miniconda_Install.sh
conda clean -iltp --yes

# Add Entry Point to the path
if [[ $EntryPoint ]]; then

    cd $InstallDir
    mkdir Scripts
    ln -s ../bin/$EntryPoint Scripts/$EntryPoint

    echo "$EntryPoint script installed to $InstallDir/Scripts"
    echo
    echo "Add folder to path by appending to .bashrc?"
    read -p "[y/n] >>> " -r
    echo
    if [[ ($REPLY == "yes") || ($REPLY == "Yes") || ($REPLY == "YES") ||
        ($REPLY == "y") || ($REPLY == "Y")]]
    then
        echo "export PATH=\"$InstallDir/Scripts\":\$PATH" >> ~/.bashrc
        echo "Your PATH was updated."
        echo "Restart the terminal for the change to take effect"
    else
        echo "Your PATH was not modified."
    fi

    cd ..
fi

echo
echo "$AppName Install Successfully"
