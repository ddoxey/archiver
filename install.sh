#!/bin/bash
##
# Install the archiver
##

if [[ $(id -u) -ne 0 ]]
then
    echo "run as root" >&2
    exit 1
fi

SYSTEMCTL=$(which systemctl)

if [[ -z $SYSTEMCTL ]]
then
    echo "can't find systemctl" >&2
    exit 1
fi

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$1" == "--disable" ]]
then
    systemctl stop archiver
    systemctl disable archiver
    rm -f /etc/archive.json
    rm -f /lib/systemd/service/archiver.service
    systemctl daemon-reload

elif [[ $# -ne 0 ]]
then
    echo "USAGE: $(basename "$0") [--disable]" >&2
    exit 1
else

    mkdir -p /var/log
    chmod 0755 /var/log
    touch /var/log/archiver.log
    chmod 0666 /var/log/archiver.log
    touch /var/log/archiver-error.log
    chmod 0666 /var/log/archiver-error.log
    ln -sf "$(pwd)/etc/archiver.json"                /etc/
    ln -sf "$(pwd)/systemd/service/archiver.service" /lib/systemd/system/
    systemctl daemon-reload
    systemctl start archiver
    systemctl enable archiver
fi
