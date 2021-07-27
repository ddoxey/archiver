from os import path
import json

CONF_FILE = '/etc/archiver.json'

class Project:

    def __init__(self, project, default):
        self.name           = project.get('name', None)
        self.path           = project.get('path', None)
        self.excludes       = project.get('excludes', default.get('excludes', None))
        self.dwell_time     = project.get('dwell_time', default.get('dwell_time', 900))
        self.archive_dir    = project.get('archive_dir', default['archive_dir'])
        self.preserve_count = project.get('preserve_count', default.get('preserve_count', 0))


def load():

    if not path.exists(CONF_FILE):
        raise Exception(f'{CONF_FILE}: No such file or directory')

    config = None

    with open(CONF_FILE, 'r') as configfile:
        config = json.load(configfile)

    projects = config.pop('projects')
    defaults = config
    projects = [Project(project, defaults) for project in projects]

    return {**defaults, 'projects': projects}
