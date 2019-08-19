#!/usr/bin/python3
# YM register dump compression trials by gunstick
# august 2019
# bye bye python2, this is my first python 3 program

# this reads a dump from sc68 and rearranges it to be less big
# test program to see which data is the smallest
# maybe could use a register frequency counter and adapt coding?

# some format format ideas: 
# inspired from YMX2
# https://github.com/Gunstick/spriterecord/blob/master/ym2ymx.pl?fbclid=IwAR0N-YjwYHH_GAVuU3liUEq8frp_TxQIZuE0-myG1iu7PH3qVu_5mml8arY#L28
# 
# or do it volume centric
# 111naAAA bBBBcCCC for the volumes
# 011nbBBB cCCCxxxx if vol a is not used
# 001ncCCC if only vol C is used
# 100naAAA if only vol A is used (a=1, AAA = EEE envelope shape)
# 10111eee 0ccc____ volA=1eee, shape=eee, volC=0ccc, volB not changed
# where to encode if other registers are set (3xfreq, noisefreq, mixer
#
# or do coding by channel
# chanel A: freq, vol, noise, envelope
# fvnxkKKK lLLLmMMM 
# if f=1, kKKK is freq, next byte is freq
# if v=1, next 4 bits (kKKK or lLLL) is volume, if env bit is set, then KKK or LLL goes to shape
# if n=1, next 4 bits is for mixer something, read next byte for noise freq
# if x=1 do the same for channel B else end frame
# if x=1 do the same for channel C else end frame

# or use Ben's method with a 2 byte bitfield at the start of each frame
# so many choices....

# for timer based routs, the timer data is the biggest
# as it's only on small amount of registers (i.e. 3 volumes and envelope)
# 1 byte the delay until next timer event. Can be from 128 to 32640 in 128 steps (total 255 values: $01 - $ff)
# if biger values needed, set the delay to $00 so will wait for 32768 + 128*next byte.
# this is resolution of 1 hbl. Could be too large for good SID, so propose is halwing it:
## 1 byte the delay until next timer event. Can be from 64 to 16320 in 64 steps (total 255 values: $01 - $ff)
## if biger values needed, set the delay to $00 so will wait for 16384 + 128*next byte. (here we don't need so high resolution)
# 2 bits to designate the register 0=volA, 1=volB, 2=volC, 3=env and 4 bits for the volume/shape
# the x bits reserved. i.e. if there are timer based arpegio. 
#
# read a line
# 00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A  
# 012345 7890123456 890123456789012345678901234567890123456789
# 000000 0001111111 111222222222233333333334444444444555555555


# YMX2 encoder
# Each VBL we read a byte, if none of the top 3 bits is set, 
# there is no frequency register to be modified.
#   If a bit is set (7,6 or 5), we store the data into register 1,3 or 5
#   and then copy the next byte into 0,2 or 4 respectively.
#   If there's still another bit set (6 or 5) do the same again.
#   This means if frequency A and C has to be modified, the first byte 
#   will have top bits like 101. If it's B and C it will be 011 etc...
# And finally if bit 4 is set, there's more data, else we have finished. 
# BYTE: abcnxxxx   abc: bitfield for freq registers n: more data to follow
# if a=1; xxxx->reg1; read BYTE->reg0; if n=1; read BYTE: 0bcnxxxx
# if b=1; xxxx->reg3; read BYTE->reg2; if n=1; read BYTE: 00cnxxxx
# if c=1; xxxx->reg5; read BYTE->reg4; 
# if n=1; read BYTE: ABCNSFEn
#                    ABC=volumes for channels a (reg  b and c 
#                       N=noise (reg6)
#                        M=mixer (on/off channels)
#                         F=envelope frequency
#                          S=envelope shape (reg13)
#                           n=future extension (SID, DRUM)
#
import sys
prevregistervalues="00-00-00-00-00-00-00-00-00-00-00-00-00-00".split("-")

inputdump = open(sys.argv[1], 'r')
incount=0
outcount=0
prevymtime=0
dumpline=inputdump.readline()
while dumpline:
  #                              0  1  2  3  4  5  6  7  8  9 10 11 12 13
  # dumpline="00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A"
  print(   "# vbl    time       freqA freqB freqC N  Mx vA vB cC freqE Sh")
  print("# "+dumpline)
  incount=incount+len(dumpline)
  vbltime=dumpline[0:6]
  ymtime=int(dumpline[7:17],16)
  print(f"{ymtime}-{prevymtime}="+hex(ymtime-prevymtime))
  prevymtime=ymtime
  outcount=outcount+2    # timestamp on 2 bytes

  registervalues=dumpline[18:59].split("-")
  for i in range(0,13):
    if registervalues[i]==prevregistervalues[i]:
      # no change
      registervalues[i]=".."
  flags=0   # abcnxxxx
  flags2=0  # ABCNMFSn
  # check freq A
  if (registervalues[0]!=".." or registervalues[1]!=".."):
    flags = flags | int('10000000',2)
  # check freq B
  if registervalues[2]!=".." or registervalues[3]!="..":
    flags = flags | int('01000000',2)
  # check freq C
  if registervalues[4]!=".." or registervalues[5]!="..":
    flags = flags | int('00100000',2)

  # frequencies done now care about other registers
  if registervalues[6]!="..":              # noise frequency
    flags2 = flags2 | int('00010000',2)    # ABC1MFSn
  if registervalues[7]!="..":              # mixer
    flags2 = flags2 | int('00001000',2)    # ABCN1FSn
  if registervalues[8]!="..":              # vol A
    flags2 = flags2 | int('10000000',2)    # 1BCNMFSn
  if registervalues[9]!="..":              # vol B
    flags2 = flags2 | int('01000000',2)    # A1CNMFSn
  if registervalues[10]!="..":             # vol C
    flags2 = flags2 | int('00100000',2)    # AB1NMFSn
  if registervalues[11]!=".." or registervalues[12]!="..":             # envelope frequency
    flags2 = flags2 | int('00000100',2)    # ABCNM1Sn
  if registervalues[13]!="..":             # envelope shape
    flags2 = flags2 | int('00000010',2)    # ABCNMF1n

  if flags2!=0:
    flags = flags | int('00010000',2)   # set abcnxxxx to abc1xxxx
    
  # we now have flags and register value.
  print( '#              abcnxxxx               ABCNMFSn')
  print(f'# flags={flags:#04x} {flags:#010b} flags2={flags2:#04x} {flags2:#010b} ')
  if flags & int('10000000',2):
    if(registervalues[1]==".."):
      print(hex(flags | int(prevregistervalues[1],16)))   # no change
    else:
      print(hex(flags | int(registervalues[1],16)))   # changed
    print(hex(int(registervalues[0],16)))  # dual conversion, to catch bad dump.
    outcount=outcount+2
  if flags & int('01000000',2):
    if(registervalues[3]==".."):
      print(hex(flags | int(prevregistervalues[3],16)))   # no change
    else:
      print(hex(flags | int(registervalues[3],16)))   # changed
    print(hex(int(registervalues[2],16)))
    outcount=outcount+2
  if flags & int('00100000',2):
    if(registervalues[5]==".."):
      print(hex(flags | int(prevregistervalues[5],16)))   # no change
    else:
      print(hex(flags | int(registervalues[5],16)))   # changed
    print(hex(int(registervalues[4],16)))
    outcount=outcount+2
  if flags & int('00010000',2):     # extended data
    outcount=outcount+1
    if flags2 & int('10000000',2):
      print(hex(int(registervalues[8],16)))
      outcount=outcount+1
    if flags2 & int('01000000',2):
      print(hex(int(registervalues[9],16)))
      outcount=outcount+1
    if flags2 & int('00100000',2):
      print(hex(int(registervalues[10],16)))
      outcount=outcount+1
    if flags2 & int('00010000',2):
      print(hex(int(registervalues[6],16)))
      outcount=outcount+1
    if flags2 & int('00001000',2):
      print(hex(int(registervalues[7],16)))
      outcount=outcount+1
    if flags2 & int('00000100',2):
      if registervalues[11]=="..":
        print(hex(int(prevregistervalues[11],16)))
      else:
        print(hex(int(registervalues[11],16)))
      if registervalues[12]=="..":
        print(hex(int(prevregistervalues[12],16)))
      else:
        print(hex(int(registervalues[12],16)))
      outcount=outcount+2
    if flags2 & int('00000010',2):
      print(hex(int(registervalues[13],16)))
      outcount=outcount+1
  for i in range(0,13):
    if registervalues[i]!="..":
      prevregistervalues[i]=registervalues[i]
  dumpline=inputdump.readline()

inputdump.close()
print(f"read {incount} bytes, wrote {outcount} bytes")
