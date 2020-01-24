#!/bin/bash

export CF_VERSION=6.49.0
wget -O /tmp/cf.tgz "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=$CF_VERSION&source=github-rel"
mkdir -p /tmp/cf
tar xfz /tmp/cf.tgz -C /tmp/cf/
chmod +x /tmp/cf/cf
mv /tmp/cf/cf /usr/local/bin/cf