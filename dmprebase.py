#!/usr/bin/python3
# takes first timestamp and adjusts all following stamps so the file starts at 0
import sys

# I tried everything in the handbook to gracefull exit the loop, nope it
# always throws an error. So well, it's like that now.
if len(sys.argv) < 2:
  print(f"usage: {sys.argv[0]} file.dmp")
  exit()
fname=sys.argv[1]
with open(fname,"rb+") as fd:

  fd.seek(7,1)   # 1=relative
  stamp=fd.read(10)
  base=int(stamp,16)
  if base == 0:
    exit()
  
  fd.seek(0,0)   # 0=absolute
  while fd.seek(7,1):   # 1=relative
    stamp=fd.read(10)
    if stamp == None:
      exit()
    time=int(stamp,16)
    time=time-base
    fd.seek(-10,1) # got back
    fd.write(f'{time:010x}'.encode())
    fd.readline()  # forward
