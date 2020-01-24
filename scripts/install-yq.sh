#!/bin/bash

export YQ_VERSION=2.4.1
wget -O /tmp/yq "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64"
chmod +x /tmp/yq
mv /tmp/yq /usr/local/bin/yq