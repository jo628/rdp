#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail

echo "Updating system packages..."
sudo apt-get update

echo "Installing XFCE4 desktop environment..."
sudo apt-get install xfce4 -y

echo "Installing XRDP for remote desktop..."
sudo apt-get install xrdp -y

echo "Setting up XFCE4 session..."
echo xfce4-session > ~/.xsession

echo "Restarting XRDP service..."
sudo service xrdp restart

echo "Downloading and installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb || true
sudo apt-get install -f -y
sudo dpkg -i google-chrome-stable_current_amd64.deb

echo "Installing Terminator terminal emulator..."
sudo apt install terminator -y

echo "Installing pip for Python 3..."
sudo apt install python3-pip -y

echo "Installing Mousepad text editor..."
sudo apt install mousepad -y

echo "Downloading and installing Go 1.24.4..."
wget https://dl.google.com/go/go1.24.4.linux-amd64.tar.gz
sudo tar -xvf go1.24.4.linux-amd64.tar.gz
sudo mv go /usr/local

# Set Go environment variables
echo "Exporting Go environment variables..."
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Persist Go environment variables (optional)
if ! grep -q 'export GOROOT=' ~/.bashrc; then
    echo "export GOROOT=/usr/local/go" >> ~/.bashrc
    echo "export GOPATH=\$HOME/go" >> ~/.bashrc
    echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
fi

echo "Installing Go tools..."
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest

echo "Setup complete!"
