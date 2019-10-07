#!/bin/bash
set -eu -o pipefail
# get crontabs | get all enabled backup crontabs | ignore full backup script | extract startup command | execute each command in bash
crontab -l | grep '^[^#].*~/backup' | grep -v 'backup.bash full' | sed s/^.*\ \ // | bash
