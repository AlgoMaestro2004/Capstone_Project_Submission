#!/bin/bash

# Create users (the shlok-devs and shlok-readers groups must already exist)
sudo useradd -m -s /bin/bash -G shlok-devs dev1
sudo useradd -m -s /bin/bash -G shlok-readers reader1
sudo useradd -m -s /bin/bash outsider

# Verify users and configure the project directory
id dev1 reader1 outsider
sudo mkdir /srv/shlok-project5
sudo chown root:shlok-devs /srv/shlok-project5/
sudo chmod 770 /srv/shlok-project5/

# Check and set ACL permissions
which setfacl
ls -ld /srv/shlok-project5/
sudo setfacl -m g:shlok-readers:rx /srv/shlok-project5/
getfacl /srv/shlok-project5/

# Create a test file as dev1
sudo -u dev1 sh -c 'echo "hello from dev1" > /srv/shlok-project5/test.txt'
sudo -u dev1 sh -c 'echo "hello from dev1" > /srv/shlok-project5/test.txt'

# Check file access
ls -l /srv/shlok-project5/
ls -l /srv/shlok-project5
sudo ls -l /srv/shlok-project5
sudo -u reader1 cat /srv/shlok-project5/test.txt
sudo -u reader1 sh -c 'echo hack >> /srv/shlok-project5/test.txt'
sudo -u outsider cat /srv/shlok-project5/test.txt
sudo -u outsider ls /srv/shlok-project5
