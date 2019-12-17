#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive


sudo apt-get update
sudo apt upgrade -y
sudo apt-get -y install clang llvm make gcc

# Golang installation variables
VERSION="1.13.5"
OS="linux"
ARCH="amd64"

# Home of the vagrant user, not the root which calls this script
HOMEPATH="/home/vagrant"
HOME="/home/vagrant"

# Updating and installing stuff
sudo apt-get update
sudo apt-get install -y git curl

if [ ! -e "/vagrant/go.tar.gz" ]; then
	# No given go binary
	# Download golang
	FILE="go$VERSION.$OS-$ARCH.tar.gz"
	URL="https://storage.googleapis.com/golang/$FILE"

	echo "Downloading $FILE ..."
	curl --silent $URL -o "$HOMEPATH/go.tar.gz"
else
	# Go binary given
	echo "Using given binary ..."
	cp "/vagrant/go.tar.gz" "$HOMEPATH/go.tar.gz"
fi;

echo "Extracting ..."
tar -C "$HOMEPATH" -xzf "$HOMEPATH/go.tar.gz"
mv "$HOMEPATH/go" "$HOMEPATH/.go"
rm "$HOMEPATH/go.tar.gz"

# Create go folder structure
GP="/vagrant/go"
GOPATH="/vagrant/go"
mkdir -p "$GP/src"
mkdir -p "$GP/pkg"
mkdir -p "$GP/bin"


# SCION setup script

cd $HOMEPATH

echo "2. Install Bazel version 0.26.1"
sudo apt-get -y install pkg-config zip g++ zlib1g-dev unzip python3
sudo curl --silent -L https://github.com/bazelbuild/bazel/releases/download/0.26.1/bazel-0.26.1-installer-linux-x86_64.sh -o bazel-0.26.1-installer-linux-x86_64.sh
bash ./bazel-0.26.1-installer-linux-x86_64.sh --user
rm ./bazel-0.26.1-installer-linux-x86_64.sh

echo "3. Install bzlcompat version v0.6:"

sudo curl --silent -L https://github.com/kormat/bzlcompat/releases/download/v0.6/bzlcompat-v0.6-linux-x86_64 -o ~/bin/bzlcompat
chmod 755 ~/bin/bzlcompat

echo '4. Make sure that you have a Go workspace setup, and that ~/.local/bin, and $GOPATH/bin can be found in your $PATH variable. For example:'

echo 'Workspace is $HOMEPATH/go'

echo 'export PATH="$HOMEPATH/.local/bin:$GOPATH/bin:$PATH"' >> ~/.profile
source ~/.profile
mkdir -p "$GOPATH"

echo '5. Check out scion into the appropriate directory inside your go workspace (or put a symlink into the go workspace to point to your existing scion checkout):'

echo 'Cloning into $GOPATH/src/github.com/joelfischerr'

mkdir -p "$GOPATH/src/github.com/joelfischerr"
cd "$GOPATH/src/github.com/joelfischerr"
git clone --single-branch --branch jf-scionproto https://github.com/joelfischerr/scion scion
cd scion
echo 'export SC="go/src/github.com/joelfischerr/scion"' >> ~/.profile

echo '6. Install required packages with dependencies:'

ls

./env/deps

echo '7, Install Docker and docker compose'

sudo apt-get update

sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl --silent -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo curl --silent -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo usermod -a -G docker $LOGNAME
sudo usermod -a -G docker vagrant



# Write environment variables, other prompt and automatic cd into /vagrant in the bashrc
echo "Editing .bashrc ..."
touch "$HOMEPATH/.bashrc"
{
	echo '# Prompt'
	echo 'export PROMPT_COMMAND=_prompt'
	echo '_prompt() {'
	echo '    local ec=$?'
	echo '    local code=""'
	echo '    if [ $ec -ne 0 ]; then'
	echo '        code="\[\e[0;31m\][${ec}]\[\e[0m\] "'
	echo '    fi'
	echo '    PS1="${code}\[\e[0;32m\][\u] \W\[\e[0m\] $ "'
	echo '}'

    echo '# Golang environments'
    echo 'export GOROOT=$HOME/.go'
    echo 'export PATH=$PATH:$GOROOT/bin'
    echo 'export GOPATH=/vagrant/go'
    echo 'export GO=/vagrant/go'
    echo 'export PATH=$PATH:$GOPATH/bin'

	echo '# Automatically change to the vagrant dir'
	echo 'cd /vagrant'
} >> "$HOMEPATH/.bashrc"

echo 'Finished setup'

echo 'You still have to run ./env/deps in scion'

echo 'You also have to run sudo usermod -a -G docker $LOGNAME after login and then logout and login again.'

# cd $SC

# ./scion.sh topology
#
# ./scion.sh start
#
# ./scion.sh status
#
# ./scion.sh stop
