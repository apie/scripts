#!/usr/bin/python
#Script to extract played songs from a shoutcast page, identify new songs and finally write them to a file which can be used by lastfmsubmitd.
#Jan 2014 by Apie
import datetime
import urllib2
import re
import yaml
import pytz
from buzhug import Base
db = Base('/home/denick/pinguin')
yamlfile = '/var/spool/lastfm/played.yaml'
#db.create(('date',datetime.datetime),('artist',str),('title',str))
url = "http://pr128.pinguinradio.nl/played.html"
headers = { 'User-Agent' : 'Mozilla/5.0' }

db.open()

req = urllib2.Request(url, None, headers)
html = urllib2.urlopen(req)
contents = html.read(3000)
m = re.match('.*Song Title</b></td></tr><tr><td>([0-9:]{8})</td><td>(.*)-(.*)<td><b>Current Song</b>.*',contents)
time = m.group(1)
yamlfile = yamlfile+time
artist = m.group(2).strip()
title = m.group(3).strip()

dateformat="%Y-%m-%d"

date = datetime.datetime.strftime(datetime.date.today(),dateformat)
timestamp=datetime.datetime.strptime(date+' '+time,dateformat+" %H:%M:%S")
#lastfmsubmitd doesnt accept timezones so convert to UTC
zone = pytz.timezone('Europe/Amsterdam')
localtimestamp = zone.localize(timestamp)
utc=pytz.UTC
timestamp = localtimestamp.astimezone(utc)

all={'artist': artist,'title': title, 'length': 120,'time': '!timestamp '+timestamp.strftime('%Y-%m-%d %H:%M:%S')}

recordsfromthisstamp = db.select(['date'],date=timestamp)

#only update if it is a non-existing entry
if len(recordsfromthisstamp)==0:
  record_id = db.insert(timestamp,artist,title)
  all={'artist': artist,'title': title, 'length': 120,'time': '!timestamp '+timestamp.strftime('%Y-%m-%d %H:%M:%S')}
  stream = file(yamlfile,'w')
  result=yaml.dump(all,default_flow_style=False)
  result=result.replace("'","")
  stream.write(result)
  stream.close()

db.close()
