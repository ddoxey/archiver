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

    mkdir -p /opt/archiver
    chmod 0755 /opt/archiver

    for file in archiver.py config.py run.sh requirements.txt README.md
    do
        echo "install: /opt/archiver/${file}"
        cp "$(pwd)/${file}" /opt/archiver/

        perms=$(awk -F. '{if ($NF == "sh") {print "0755"} else {print "0644"}}' <<< "$file")

        chmod "$perms" "/opt/archiver/${file}"
    done

    mkdir -p /var/log
    chmod 0755 /var/log

    touch /var/log/archiver.log
    chmod 0666 /var/log/archiver.log

    touch /var/log/archiver-error.log
    chmod 0666 /var/log/archiver-error.log

    if [[ -e /etc/archiver.json ]]
    then
        echo "already exists: /etc/archiver.json"
    else
        echo "install: /etc/archiver.json"
        cp "$(pwd)/etc/archiver.json" /etc/
    fi

    for pid_dir in /var/run /var/bin /run /opt/archiver
    do
        if [[ -d "$pid_dir" ]]
        then
            sed -i "s|<PID_DIR>|$pid_dir|" systemd/service/archiver.service
            break
        fi
    done

    echo "setup: archiver daemon"
    cp "$(pwd)/systemd/service/archiver.service" /lib/systemd/system/

    systemctl daemon-reload
    systemctl enable archiver
    systemctl start archiver
fi
