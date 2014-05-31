#!/usr/bin/env python
#
# zypphist.py
#
# Copyright (C) 2011: Michael Hamilton
# http://codeincluded.blogspot.nl/2011/12/
#  opensuse-changelogs-for-recent-updates.html
# The code is GPL 3.0(GNU General Public License)
# ( http://www.gnu.org/copyleft/gpl.html )
#
# Output RST by Apie
# You can now easily convert to HTML like this:
# python zypphistory.py | rst2html.py - history.html

import csv
import subprocess
from datetime import datetime, timedelta
from optparse import OptionParser

zyppHistFilename = '/var/log/zypp/history'

optParser = OptionParser(
    description='Report change log entries for recent installs (zypper/rpm).')
optParser.add_option(
    '-i', '--installed-since', dest='INSTALLDAYS', type='int', default=1,
    help=
    'Include anything installed up to INSTALLDAYS days ago (default 1).')
optParser.add_option(
    '-c', '--changedSince', dest='CHANGEDAYS', type='int', default=60,
    help=
    'Report change log entries from up to CHANGEDAYS days ago (default 60).')
(options, args) = optParser.parse_args()

installedSince = datetime.now() - timedelta(days=options.INSTALLDAYS)
changedSince = datetime.now() - timedelta(days=options.CHANGEDAYS)

zyppHistReader = csv.reader(open(zyppHistFilename, 'rb'), delimiter='|')

title = '%d day changelogs of software installed in the last %d days' % (
    options.CHANGEDAYS, options.INSTALLDAYS)
print title
print '-' * len(title)

for historyRec in zyppHistReader:
    if historyRec[0][0] != '#' and historyRec[1] == 'install':
        installDate = datetime.strptime(historyRec[0], '%Y-%m-%d %H:%M:%S')
        if installDate >= installedSince:
            packageName = historyRec[2]
            print ''
            packagenameanddate = '%s %s' % (installDate, packageName)
            print packagenameanddate
            print '=' * len(packagenameanddate)
            print ''
            rpmProcess = subprocess.Popen(
                ['rpm', '-q', '--changelog', packageName],
                shell=False, stdin=None, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                close_fds=True)
            rpmProcess.wait()
            if rpmProcess.returncode != 0:
                print '*** ERROR (return code was ', rpmProcess.returncode, ')'
            for line in rpmProcess.stderr:
                print line,
            for line in rpmProcess.stdout:
                try:
                    if line[0] == '*' and line[1] == ' ' and len(line) > 17:
                        changeDate = datetime.strptime(line[6:17], '%b %d %Y')
                        line = line[2:len(line)]
                        if changeDate < changedSince:
                            break
                except ValueError:
                    pass  # not a date - move on
                print line
            rpmProcess.stdout.close()
            rpmProcess.stderr.close()
