#!/bin/bash

# This scripts shared an amount of parameters similar to kubenetes/git-sync
# As original repo has couple of issue on centos host, this is used instead for workaround

# Environments variables
#  GIT_SYNC_PRIVATE_KEY
#   - this will be written to private key file if provided
#  GIT_SYNC_REPO
#   - Repository URL
 
set -e

# The parameters mainly consumes from environment

privateKeyFile="/root/.ssh/id_rsa"

mkdir -p /root/.ssh

if [ -n "$GIT_SYNC_PRIVATE_KEY" ]; then
    echo "$GIT_SYNC_PRIVATE_KEY" > "$privateKeyFile"
fi

if [ -f "$privateKeyFile" ]; then
    chmod 400 "$privateKeyFile"
    chown $(id -u):$(id -g) "$privateKeyFile"
fi

if [ -z "$GIT_SYNC_REPO" ]; then
    echo "You must supply repository url through environment: GIT_SYNC_REPO"
    exit 1
fi

gssh="$GIT_SYNC_SSH"
grepo="$GIT_SYNC_REPO"
gbranch="${GIT_SYNC_BRANCH:-master}"
gdepth="${GIT_SYNC_DEPTH:-0}"
groot="${GIT_SYNC_ROOT:-/git}"
gchown="$GIT_SYNC_CHOWN"
gchgrp="$GIT_SYNC_CHGRP"
gmod="${GIT_SYNC_PERMISSIONS:-0}"
gusername="$GIT_SYNC_USERNAME"
gpassword="$GIT_SYNC_PASSWORD"
gwait="${GIT_SYNC_WAIT:-30}"
gextra="${GIT_EXTRACOMMAND}"

gitcmd="git clone $grepo --branch $gbranch --single-branch "

# Clone with depth
if [ "$gdepth" != "0" ]; then
    gitcmd="$gitcmd --depth $gdepth"
fi
gitcmd="$gitcmd $groot"


ModChanges()
{
    if [ "$gmod" != "0" ]; then
        chmod -R $gmod $groot
    fi
    if [ -n "$gchown" ]; then
        chown -R $gchown $groot
    fi
    if [ -n "$gchgrp" ]; then
        chgrp -R $gchgrp $groot
    fi
    if [ -n "$gextra" ]; then
    	echo "running extra commands"
        eval "$gextra"
    fi
}

if [ -n "$gssh" ]; then
    echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" >> /root/.ssh/config
fi

if [ -n "$gusername" ] && [ -n "$gpassword" ]; then
    git config --global credential.helper cache
    echo "url=$grepo\nusername=$gusername\npassword=$gpassword\n" | git credential approve
fi


if [ -d "$groot/.git" ]; then
	echo ".git folder exists, pull only.."
else
	echo "fresh folder, clean and clone"
    find "$groot" -mindepth 1 -delete
    eval "$gitcmd"
    ModChanges
fi

cd $groot
ModChanges

while true
do
    git pull
    ModChanges
    sleep $gwait
done

