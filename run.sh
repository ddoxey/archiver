#!/bin/bash
##
# run the archiver
##

export CONF="/etc/archiver.json"

if [[ ! -f "$CONF" ]]
then
    echo "No such file: $CONF" >&2
    exit 1
fi

export LOG="$(awk -F'"' '/"log_file"/{print $(NF-1)}' "$CONF")"
export ERR="$(awk -F'"' '/"err_log_file"/{print $(NF-1)}' "$CONF")"

for log_file in LOG ERR
do
    if [[ -z ${!log_file} ]]
    then
        echo "$log_file required in: $CONF" >&2
        exit 1
    fi

    if [[ ! -e ${!log_file} ]]
    then
        touch "${!log_file}"      || exit 1
        chmod 0644 "${!log_file}" || exit 1
    fi
done

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "START ARCHIVER: $(date)" >> $LOG
echo "PWD: $(pwd)"             >> $LOG

if [[ -e venv ]]
then
    source venv/bin/activate

    echo 'VENV: activated' >> $LOG
else
    python3 -m venv venv

    source venv/bin/activate

    echo 'VENV: activated' >> $LOG

    if [[ -s requirements.txt ]]
    then
        venv/bin/python -m pip install -r requirements.txt
    fi
fi

export PYTHONPATH="$(pwd):$(find venv/ -type d -name 'site-packages'):$PYTHONPATH"

export PYTHON=$(which python)

for var in LOG ERR PYTHONPATH PYTHON USER HOME SHELL VIRTUAL_ENV
do
    echo "$var: ${!var}" >> $LOG
done

$PYTHON archiver.py 2>>$ERR >> $LOG

deactivate
