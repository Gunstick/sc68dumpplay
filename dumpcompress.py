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

import sys
import re
import binascii

def main():
  if len(sys.argv) < 3:
    print(f"usage: {sys.argv[0]} ymx2|ympkst dumpfile")
  else:
    choosealgo(sys.argv[1])
def choosealgo(aname):
  switcher = {
     "ymx2": ymx2encode,
     "ympkst": ympkst
  }
  func = switcher.get(aname, lambda: print("no such algo"))     
  func()  # call the encoder function

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

def ymx2encode():
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
  prevregistervalues="00-00-00-00-00-00-00-00-00-00-00-00-00-00".split("-")

  inputdump = opendump(sys.argv[2])
  prevymtime=0
  dumpline=readdump(inputdump)
  while dumpline:
    vbltime=dumpline[0:6]
    ymtime=int(dumpline[7:17],16)
    writedump(inputdump,ymtime-prevymtime,4,f"{ymtime}-{prevymtime}=")
    prevymtime=ymtime
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
    print( '#              abcnxxxx               ABCNMFSn', file=inputdump["outtxtfd"])
    print(f'# flags={flags:#04x} {flags:#010b} flags2={flags2:#04x} {flags2:#010b} ', file=inputdump["outtxtfd"])
    if flags & int('10000000',2):
      if(registervalues[1]==".."):
        writedump(inputdump,flags | int(prevregistervalues[1],16),1,"")
      else:
        writedump(inputdump,flags | int(registervalues[1],16),1,"")
      writedump(inputdump,int(registervalues[0],16),1,"")
    if flags & int('01000000',2):
      if(registervalues[3]==".."):
        writedump(inputdump,flags | int(prevregistervalues[3],16),1,"")
      else:
        writedump(inputdump,flags | int(registervalues[3],16),1,"")
      writedump(inputdump,int(registervalues[2],16),1,"")
    if flags & int('00100000',2):
      if(registervalues[5]==".."):
        writedump(inputdump,flags | int(prevregistervalues[5],16),1,"")
      else:
        writedump(inputdump,flags | int(registervalues[5],16),1,"")
      writedump(inputdump,int(registervalues[4],16),1,"")
    if not (flags & int('11100000',2)):     # no freq registers
      writedump(inputdump,flags,1,"")
    if flags & int('00010000',2):     # extended data
      writedump(inputdump,flags2,1,"")
      if flags2 & int('10000000',2):
        writedump(inputdump,int(registervalues[8],16),1,"")
      if flags2 & int('01000000',2):
        writedump(inputdump,int(registervalues[9],16),1,"")
      if flags2 & int('00100000',2):
        writedump(inputdump,int(registervalues[10],16),1,"")
      if flags2 & int('00010000',2):
        writedump(inputdump,int(registervalues[6],16),1,"")
      if flags2 & int('00001000',2):
        writedump(inputdump,int(registervalues[7],16),1,"")
      if flags2 & int('00000100',2):
        if registervalues[11]=="..":
          writedump(inputdump,int(prevregistervalues[11],16),1,"")
        else:
          writedump(inputdump,int(registervalues[11],16),1,"")
        if registervalues[12]=="..":
          writedump(inputdump,int(prevregistervalues[12],16),1,"")
        else:
          writedump(inputdump,int(registervalues[12],16),1,"")
      if flags2 & int('00000010',2):
        writedump(inputdump,int(registervalues[13],16),1,"")
    for i in range(0,13):
      if registervalues[i]!="..":
        prevregistervalues[i]=registervalues[i]
    dumpline=readdump(inputdump)

  closedump(inputdump,ymtime)


def ympkst():
  # file format by Benjamin Gerard AKA Ben/OVR
  #
  # YM Packed Stream starts with a 16 bytes header defined as follow:
  #
  # offset | size | description
  # -------|------|------------
  # 00 | +6 | "YMPKST" magic string
  # 06 | +1 | $30 ('0') + version
  # 07 | +1 | $30 ('0') + flags
  # 08 | +4 | clock (hz) big endian uint32
  # 12 | +4 | data size big endian uint32 (0 if unknown)
  # Data Packets
  # ------------
  #
  # Each packet starts with a time-stamp that represents the number of
  # clock cycles elapsed. It's 32-bit big endian variable length
  # unsigned integer. Similar to UTF-8 encoding the bit-7 of each byte
  # is set when there is a following byte (0x7F encodes 127, 0x0100
  # encode 128).
  #
  # A time-stamp of 0xFFFFFFFF marks the end of the stream which is
  # necessary when the header is missing the size component.
  #
  #
  # Binary Packet coding
  # --------------------
  #
  # byte-0    | byte-1    | description
  # --------- | --------- | -----------
  # 0089ABCD  | 01234567  | 00 + a bit set means named register is present (followed by all bytes starting at R0)
  # 01xxxxxx  |           | reserved    (timer values perhaps?)
  # 1rr.....  |           | quick set for volume register R(7+0brr)   01 <= rr <= 11
  # 1rr0nnnn  |           | Rr:={0nnnn}     rr=01 => R8, 10 => R9, 11 => R10
  # 1rr10000  |           | Rr:=0x10    = use envelope
  # 1rr10100  |           | hardsync on period for register rr (01<=rr<=11)
  # 1rr100xx  |           | reserved
  # 1rr11DDD  |           | Rr:=0x10 and R13={1DDD}   = use envelope and set envelope
  #### if rr==0b00
  # 10008888  | AAAA9999  | R8:={8888},  R9:={9999}, R10:={AAAA}  i.e. for digi sound
  # 1001rrrr  | YYYYYYYY  | Rr:={YYYYYYYY}    i.e. for R7 (mixer): 10010111-00011011
  # 10011110  | YYYYYYYY  | reserved (could be STE channel mix L^R)
  # 10011111  | YYYYYYYY  | reserved (could be STE channel mix R)
  ####per register example:
  # 1010nnnn  |           | R8:={nnnn}
  # 10110000  |           | R8:=0x10
  # 10110xxx  |           | reserved
  # 10111DDD  |           | R8:=0x10 and R13:={1DDD}
  # 1100nnnn  |           | R9:={nnnn}
  # 11010000  |           | R9:=0x10
  # 11010xxx  |           | reserved
  # 11011DDD  |           | R9:=0x10 and R13:={1DDD}
  # 1110nnnn  |           | R10:={nnnn}
  # 11110000  |           | R10:=0x10
  # 11110xxx  |           | reserved
  # 11111DDD  |           | R10:=0x10 and R13:={1DDD}


  # note: as a 00 frame is followed by each register value as a byte, and a volume only change is also
  # taking 2 bytes (needs each time to have a clock header), if an update changes 2 vol registers, the size requirement
  # is for a 00 frame: 2bytes for the bitfield + 2 bytes for the volumes. => 4 bytes
  # and using 2 1rr frames: 1 byte for vol1 and 1 byte for 00 clock and 1 byte for vol2 => 4 bytes
  # So even if 2 volumes are changed, it is same size to use it a 00 frame bitfield or use two 1rr frames.
  # if 3 volumes are changed, use the 1110 frame (2 bytes instead of 5) and 00 clock + 1 byte for which voice has envelope
  # as envelope is mostly only on 1 channel, what about 01ee8888 9999AAAA where ee says which voice has env. 00=none
  # 01108888 1DDDAAAA sets R8=08888 R9=10000 R10=0AAAA R13=1DDD   (ee=10 => envelope on R9)
  # 01118888 99990xxx sets R8=08888 R9=09999 R10=10000    (ee=11, envelope on R10, not set R13)
  # 01008888 0000AAAA sets R8=08888 R9=09999 R10=0AAAA  only simply set volume (i.e. for digi sound)
  # which renders 1110.... useless and can be used as below
  # so the 3 volume registers and shape regiser are not needed in the 00 frame. => 4 bits for other use.
  # 00xCBxxx  | 76543210  |    <= this was the old 00 frame, with the useless bits x-ed out
  # so in YMPKST11 we have 2 bitfield frames of 1 byte:
  # 00543210  | 00000000 xxxx1111 22222222 xxxx3333 44444444 xxxx5555  freq regs
  # 1110CB76  | xxx66666 xx777777 BBBBBBBB CCCCCCCC   to set noise, mixer and  envelope frequency

  # issue with syncbuzz, the current encoding writes volum and shape each time even if volume has already
  # selected buzz. Idea is to use another command for the envelope
  # rrsss : rr=voice 01, 10, 11. sss = shape. If rr=00 then only write shape, but don't enable on any voice.
  # to disable buzz on a voice, write normally any volume 



  ympkstmagic="YMPKST"
  ympkstversion=1
  ympkstflags=0
  inputdump = opendump(sys.argv[2])
  writedump(inputdump,''.join(f'{ord(c):02x}' for c in ympkstmagic),-1,ympkstmagic)
  #print("# "+ympkstmagic)  # magic string
  #print(''.join(str(ord(c)) for c in ympkstmagic))
  #print(f"# v={ympkstversion} flags={ympkstflags}")      # version , flags
  #print(f'{ympkstversion+0x30:02x}{ympkstflags+0x30:02x}')           # each one byte char
  writedump(inputdump,f'{ympkstversion+0x30:02x}{ympkstflags+0x30:02x}',-1,f"# v={ympkstversion} flags={ympkstflags}")
  # better to use an mfp clock to play it nicer on ST
  # see ym2mfp for the conversion
  # int(round(current.clk * mfp_clk / mfp_div / psg_clk)) 
  # mfp_clk = 2457600.0
  # mfp_div = 16
  # psg_clk = 8010690.0/4       # Approx
  # i.e. prediv 16 gives a resolution of 153.6KHZ
  # means for a 1 vbl clock the ym does 40064 ticks
  # with an mfp at 153kht, this gives a count of 3069 timer ticks per vbl
  # so the player has to divide that by 256 and ignore 11 interrupts and count 253 ticks more
  # 3069>>8=11, 3069&255=253
 
  # define the ST
  mfp_clk = 2457600.0
  mfp_div = 16
  # atari used various quartz components, and emulators too
  pal_quartz     =32084988
  median_quartz  =32042760
  saint_quartz   =32084992   # also hatari, sc68. Best for mfp conversions
  ntsc_odd_quartz=32028400   # paolo simoes' ST
  ntsc_stf_quartz=32042400
  ntsc_ste_quartz=32215905
  psg_clk = 8010690.0/4    
  psg_clk = int(saint_quartz/4/4)   # something around 2Mhz
  mfp_adjust=mfp_clk / mfp_div / psg_clk

  #writedump(inputdump,psg_clk,4,"clock 2Mhz on big endian uint32")   # YM on ST is 2MHz
  writedump(inputdump,int(round(psg_clk * mfp_adjust)),4,"mfp timer in Mhz on big endian uint32")   # YM on ST is 2MHz
  writedump(inputdump,0,4,"data size big endian uint32 (0 if unknown)")

  prevregistervalues="..-..-..-..-..-..-..-..-..-..-..-..-..-..".split("-")
  
  prevymtime=0
  mfp_ticks=0     # this is the pseudo mfp counter, where we accumulate deltas
  flags=0
  dumpline="x"   # to enter the loop
  while dumpline:
    dumpline=readdump(inputdump)
    if not(dumpline):
      break
    #                              0. 1  2. 3  4. 5  6  7  8  9 10 11 12 13
    # dumpline="00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A"
    #           000000000011111111112222222222333333333344444444445555555555
    #           012345678901234567890123456789012345678901234567890123456789
    vbltime=dumpline[0:6]
    ymtime=int(dumpline[7:17],16)
    #registervalues=dumpline[18:59].split("-")
    registervalues=re.split('[-:]',dumpline[18:59])
    hardsync=0
    print(f'# hs detect: A={dumpline[20:21]} B={dumpline[26:27]} C={dumpline[32:33]}', file=inputdump["outtxtfd"])
    if dumpline[20:21] == ":" :
      hardsync=(hardsync | 1)
    if dumpline[26:27] == ":" :
      hardsync=(hardsync | 0b010)
    if dumpline[32:33] == ":" :
      hardsync=(hardsync | 0b100)
    print(f'# hs detect: {hardsync:03b}', file=inputdump["outtxtfd"])
    if registervalues[13] != "..":
      shape=int(registervalues[13],16)
      if shape<8:    # if lower shape, convert it to upper
        if shape<4:
          shape=9
        else:
          shape=15
    else:
      shape=0
      
    # optimize registers
    for i in range(0,13):    # end of range (i.e. shape) not included
      if registervalues[i]==prevregistervalues[i]:
        # no change
        registervalues[i]=".."

    # create bit pattern of present registers
    for i in range(13,-1,-1):    # end of range not included
      if registervalues[i]=="..":
        # shift in 0
        flags=(flags<<1)+0
      else:
        # shift in 1 
        flags=(flags<<1)+1
    # we now have a bitfield with a 1 for every register if it's present
    # if nothing is changed, read the next line, without outputting
    if flags == 0 and hardsync==0:
      continue

    # convert a 2Mhz ym clock value to an mfp clock value with int, so we take into account precision errors on decompress:
    # mfp_ticks is the current timer based clock (i.e. at 2400*256 Hz)
    # ymtime is the value of the ym clock we want to get close to
    # convert ymtime into mfp ticks
    target_mfp_ticks=int(round(ymtime*mfp_adjust))
    # how much does the mfp have to run from mfp_ticks to target_mfp_ticks to get there
    mfp_delta=target_mfp_ticks-mfp_ticks
    # the decompressor will do the calculation like this. Just explicilty do it
    mfp_ticks=mfp_ticks+mfp_delta   # mfp_ticks is the decompressor counter
    # for displaying, calculate the offset from the target
    ym_mfp_offset=int(ymtime-target_mfp_ticks/mfp_adjust)
    # write the delta to the yms file 
    writedump(inputdump,ympkstcycles(mfp_delta),-1,f'{ymtime:08x}-{int(mfp_ticks/mfp_adjust):08x}={ym_mfp_offset:08x}(ymticks) mfpdelta:{mfp_delta:x}') 
    #prevymtime=prevymtime+int(mfp_ticks/mfp_adjust)
    # do hardsync first (we rarely have 3 hardsyncs at the same time, but who knows...)
    channelnr=1
    while hardsync != 0:
      if hardsync & 1:     #  1rr10100
        writedump(inputdump,0b10010100 | channelnr<<5 , 1 , f'hardsync on voice {channelnr-1}')
        hswritten=1
      hardsync=hardsync>>1
      channelnr=channelnr+1
      if hswritten and (hardsync!=0 or flags!=0):
        writedump(inputdump,0,1,'hardsync and more, so need zero clock frame')
      hswritten=0
    if flags==0:
      continue 

    # need to decide which method to use for encoding
    # check if only shape register written
    if flags == 1<<13:    # only bit for R13 is set
      # check on which channel is the envelope applied, and use that one for setting shape
      # frame looks like 1rr11DDD   rr=00 => 00 = R8, 01 => R9, 10 => R10
      for i in range(8,11):    # test the 3 registers
        if int(prevregistervalues[i],16) > 15:
          break
      if int(prevregistervalues[i],16) > 15:   # we effectively found a register
        i=(i-7)<<5 # convert it to rr
        #                     1rr11DDD |           | Rr:=0x10 and R13={1DDD}   = use envelope and set envelope
        writedump(inputdump,0b10011000 | i | shape, 1 , f'R{i+7} shape {shape:04b}')
        flags=flags & ~(1<<13)
        
    # check if only 1 volume is changed => 1 byte
    if flags == 1<<8:     # is R8 set?
      writedump(inputdump,0b10100000 | int(registervalues[8],16) | shape,1,'volA')
      flags=flags & ~(1<<8)
    if flags == 1<<9:     # is R9 set?
      writedump(inputdump,0b11000000 | int(registervalues[9],16) | shape,1,'volB')
      flags=flags & ~(1<<9)
    if flags == 1<<10:    # is R10 set?
      writedump(inputdump,0b11100000 | int(registervalues[10],16) | shape,1,'volC')
      flags=flags & ~(1<<10)
       

    # other methods:
 
    # check if exactly 1 bit remains set, then use   1111XXXX  | YYYYYYYY
    # https://stackoverflow.com/questions/51094594/how-to-check-if-exactly-one-bit-is-set-in-an-int
    if flags and not(flags & (flags-1)):
      # so it's a power of 2, which register is that?
      reg=0
      i=1
      while ((i & flags) == 0):
        i = i << 1
        reg += 1
      writedump(inputdump,((0b10010000 | reg)<<8) + int(registervalues[reg],16),2,f'single register set is {reg} to value {registervalues[reg]}')
      flags = flags & ~(1<<reg)
 
    # test if volumes ABC are set together<0x10, write 111088889999AAAA frame (usually sound sample) 2 bytes
    # could bit test, but still needs to test regs directly, so just do that

    # if there are single registers to write, do it with a 1111XXXXYYYYYYYY frame (2 bytes)

    # if nothing works, just use the simple dumb way: just wite it all out (2 bytes + number of registers)
    if flags != 0:   # still registers left?
      print(                     "#       0089ABCD01234567", file=inputdump["outtxtfd"])
      rotflags=int("".join(reversed(f'{(flags&0xff00)>>6:08b}')) +"".join(reversed(f'{flags&0xff:08b}')),2)
      writedump(inputdump,rotflags,2,f'flags={rotflags:016b}')
      for i in range(0,14):    # end of range not included
        if 1<<i & flags:
          writedump(inputdump,registervalues[i],1,f'R{i} present.')

    # save current values as previous YM state
    for i in range(0,13):
      if registervalues[i]!="..":
        prevregistervalues[i]=registervalues[i]
    flags=0

  closedump(inputdump,ymtime)

  
def ympkstcycles(ticks):
  # input is an integer
  # returns as hex string the variable length unsigned integer big endian
  # ympkstcycles(0)     =>   "00"
  # ympkstcycles(127)   =>   "7f"
  # ympkstcycles(128)   =>  "8100"    81 => top bit set. take 01<<7 plus next byte
  # ympkstcycles(16383) =>  "ff7f"    ff => top bit set. Take 7f<<7 plus next byte 7f
  # ympkstcycles(16384) =>"818000"    ((0x81 & 0x7f) <<14) + ((0x80 & 0x7f) <<7) + 0x00
  # ympkstcycles(1234567) => "cbad07" ((0xcb & 0x7f) <<14) + ((0xad & 0x7f) <<7) + 0x07
  # big endian is the beloved mc68000 format. not the intel mess
  ticksout=[]    # empty stack
  moreticks=0
  while ticks>0:
    #if len(ticksout) > 0:
    #  ticksout[0]=ticksout[0] | 0b10000000 # set top bit of previous (except for first time)
    if ticks> 127:      # too big to fit a byte
      ticksout.append(moreticks | ( ticks & 0b01111111 ))    # take lower 7 bits, force bit 8 = 1
      moreticks=0b10000000
    else:
      ticksout.append(ticks)
    ticks=ticks>>7   # shift by 7 
  ticksout.reverse()
  if len(ticksout) > 0:
    ticksout[0]=ticksout[0] | moreticks
  else:
    ticksout.append(0)
  return "".join(f'{e:02x}' for e in ticksout)
  
def opendump(fname):   # future: return opject with opened in and multiple out files (ascii, binary)
   # welcome to python: dicts are initiated withh {} but indexed with []
   return {
     "infd": open(fname, 'r'),    # reading file
     "outbinfd": open(fname+".yms",'wb'),   # writing binary data
     "outtxtfd": open(fname+".ascii",'w'),   # writing ascii debug 
     "outcount": 0,               # counts effective number of bytes written
     "incount" : 0               # counts each time bytes are written
   }

def readdump(fd):    
  # uuh, nasty a read function with outputs stuff?
  # this should go in future into a debugging parameter
  #                              0  1  2  3  4  5  6  7  8  9 10 11 12 13
  # dumpline="00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A"
  dumpline=fd["infd"].readline()
  # calculate as incount an brute force register list with 2 byte flag which registers are changed
  fd["incount"]=fd["incount"]+4    # ym time on 4 bytes
  fd["incount"]=fd["incount"]+2    # the 2 bytes flag
  fd["incount"]=fd["incount"]+len(dumpline[18:59].replace('.','').replace('-',''))/2   # the changed registers
  print(   "# vbl    time       freqA freqB freqC N  Mx vA vB vC freqE Sh", file=fd["outtxtfd"])
  print("# "+dumpline, end='', file=fd["outtxtfd"])
  return dumpline   

def writedump(fd,value,length,comment):     # fd not used yet
  # if length=-1, use the length of value (only works for hex string)
  if length==-1:
    length=int(len(value)/2)    # will make an error if not a string
  if comment != "":
    print(f'# {comment} v={value} l={length}', file=fd["outtxtfd"])
  try: 
    hexstring=f'{value:0{length*2}x}' # print hex if it's an integer
  except ValueError:
    hexstring=f'{value:0>{length*2}}' # print as string
  print(hexstring, file=fd["outtxtfd"])
  fd["outbinfd"].write(binascii.unhexlify(hexstring))
  fd["outcount"]=fd["outcount"]+length

def closedump(fd,ymt):
  print(f'#read {fd["incount"]} bytes, wrote {fd["outcount"]} bytes ({(1-fd["outcount"]/fd["incount"])*100:.2f}%), for {ymt/40064/50:.2f} s = {fd["outcount"]/(ymt/40064/50):.2f} bytes/s', file=fd["outtxtfd"])
  fd["infd"].close()
  fd["outbinfd"].close()
  fd["outtxtfd"].close()
# welcome to python
if __name__=="__main__":
   main()
