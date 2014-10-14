#!/bin/python
import string

alphabet = ['']*27

def getcol(i):
  print '%i ' % (i),
  if i > 26:
    j = (i-1)/26
    return getcol(j)+getcol(i-26*j)
  return alphabet[i]

j=1
for i in string.ascii_lowercase:
  alphabet[j]=i
  j = j+1

for i in range(1,54,1):  
  print getcol(i)
