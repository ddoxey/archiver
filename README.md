# Synopsis
The Archiver Service periodically bundles archive snapshots.

# Why
This satisfies the use case of projects that are somewhere between
rough notes and ready for public source control. The Archiver
service will TAR up your working files and drop the bundle
on a space limited shared drive, such as Dropbox, for example.

# Details
Each project directory is described in: /etc/archiver.json

```
{
    "dwell_time": 900,                 # time between archives
    "archive_dir": "/opt/archive",     # location of archives
    "preserve_count": 3,               # how many to preserve
    "projects": [
        {
            "name": "archiver",        # project name
            "path": "/opt/archiver",   # project dir to be archived
            "excludes": [              # patterns to exclude
                "venv",
                "__pycache__",
                ".swp"
            ]
        },
        {
            "name": "ddb",
            "path": "/opt/ddb",
            "preserve_count": 10,   # override global default
            "archive_dir": "/tmp",  # override global default
            "excludes": [
                "venv",
                "__pycache__",
                ".swp"
            ]
        }
    ]
}
```
