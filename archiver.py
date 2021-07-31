"""The Archiver Service periodically bundles archive snapshots."""
from os import getpid, walk, remove, path
from sys import stderr
import subprocess
from glob import glob
from time import sleep
from datetime import datetime
from tempfile import gettempdir
import config


def log_txt(*tokens):
    """Print message with timestamp and PID."""
    pid = getpid()
    date = datetime.now().strftime('%Y-%m-%d %T')
    msg = ' '.join(tokens)
    return f'{date} [{pid}] {msg}'


def info(*tokens):
    """Print message with timestamp and PID."""
    text = log_txt(*tokens)
    print(text, flush=True)


def warn(*tokens):
    """Print message to stderr with timestamp and PID."""
    text = log_txt(*tokens)
    print(text, file=stderr, flush=True)


def matches(filepath, tokens):
    """Compare the filepath with each of the tokens."""
    if tokens is None:
        return False
    for token in tokens:
        if token[0] == '.' and filepath.endswith(token):
            return True
        if filepath.startswith(path.join(token, "")):
            return True
        if path.join("", token, "") in filepath:
            return True
    return False


def make_archive_filepath(project, key='*'):
    """Create a filename for a new project archive."""
    return path.join(project.archive_dir, f'{project.name}-{key}.tgz')


def get_archive_mtimes(project):
    """Build a map of archive mtimes to archive filenames."""
    archive_for = {}
    archive_pattern = make_archive_filepath(project)
    archive_pattern = path.join(project.archive_dir, archive_pattern)
    for archive_filepath in glob(archive_pattern):
        mtime = path.getmtime(archive_filepath)
        archive_for[mtime] = archive_filepath
    return archive_for


def get_archive_mtime(project):
    """Get the most recent archive mtime."""
    archive_for = get_archive_mtimes(project)
    if len(archive_for) == 0:
        archive_for[0] = None
    return max(archive_for.keys())


def get_project_mtime(project):
    """Get the most recent mtime of any non-excluded project file."""
    mtimes = [0]
    for root, _, filenames in walk(project.path):
        for filename in filenames:
            full_path = path.join(root, filename)
            relative_path = full_path.replace(project.path, "")
            if not matches(relative_path, project.excludes):
                mtimes.append(path.getmtime(full_path))
    return max(mtimes)


def is_ready(project):
    """Determine if a project is ready for archiving."""
    if not path.exists(project.path):
        info(f'PROJECT({project.name}) No such directory: {project.path}')
        return False

    archive_mtime = get_archive_mtime(project)
    archive_age = datetime.now().timestamp() - archive_mtime

    if archive_age < project.dwell_time:
        info(f'PROJECT({project.name}) AGE({archive_age}): Not old enough for archiving')
        return False

    project_mtime = get_project_mtime(project)

    if project_mtime <= archive_mtime:
        info(f'PROJECT({project.name}): Has not changed SINCE({archive_mtime})')
        return False

    return True


def remove_old_archives(project):
    """Remove old archives that exceed the configured preserve_count."""
    preserve_count = 1 + project.preserve_count
    archive_for = get_archive_mtimes(project)
    mtimes = list(reversed(sorted(archive_for.keys())))
    if len(mtimes) > preserve_count:
        mtimes = mtimes[preserve_count:]
        for mtime in mtimes:
            filepath = archive_for[mtime]
            info(f'PROJECT({project.name}): Removing old archive {filepath}')
            remove(filepath)


def archive(project):
    """Update the archive collection for a project."""
    date = datetime.now().strftime('%Y%m%d-%H%M')
    archive_filepath = make_archive_filepath(project, date)
    dirname = path.dirname(archive_filepath)

    if not path.exists(dirname):
        warn(f'{dirname}: No such directory')
        return False

    temp_filepath = path.join(gettempdir(), path.basename(archive_filepath))

    if getattr(project, 'excludes') is None:
        excludes = []
    else:
        excludes = [f'--exclude={e}'.replace('=.', '=*.')
                    for e in project.excludes]

    tar = ['/usr/bin/tar',
           '-C', project.path,
           *excludes,
           '-czf', temp_filepath, '.']

    subprocess.run(tar, check=False)

    if not path.exists(temp_filepath):
        warn(f'{temp_filepath}: Failed to create')
        return False

    subprocess.run(['/usr/bin/mv',
                    '-f', temp_filepath, archive_filepath],
                   check=False)

    remove_old_archives(project)

    return True


def archiver():
    """Execute the archiver event loop."""
    info('Initialize Archives')

    conf = config.load()

    for project in conf['projects']:
       info(f'PROJECT({project.name}): {project.path}')

    while True:

        info('Loading config:', config.CONF_FILE)

        conf = config.load()

        if not path.isdir(conf['archive_dir']):
            warn("Directory doesn't exist:", conf['archive_dir'])
            break

        for project in conf['projects']:

            if is_ready(project):
                archive(project)

        info(f"Dwell {conf['dwell_time']} seconds")

        sleep(conf['dwell_time'])


if __name__ == '__main__':
    archiver()
