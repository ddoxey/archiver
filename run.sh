#!/bin/bash
##
# run the archiver
##

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Start archiver: $(date)" >> /var/archiver.log
echo "PWD: $(pwd)"i            >> /var/archiver.log

if [[ -e venv ]]
then
    source venv/bin/activate

    echo 'activated' >> /var/archiver.log
else
    python3 -m venv venv

    source venv/bin/activate

    venv/bin/python -m pip install -r requirements.txt
fi

which python >> /var/archiver.log

export PYTHONPATH="$(pwd):$(find venv/ -type d -name 'site-packages'):$PYTHONPATH"

env >> /var/archiver.log

venv/bin/python archiver.py 2>>/var/log/archiver-error.log >> /var/archiver.log

deactivate
