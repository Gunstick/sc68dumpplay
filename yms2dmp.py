#!/usr/bin/python3
# convert yms binary to a typical sc68 register dump

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
  # 1rr10xxx  |           | reserved
  # 1rr11DDD  |           | Rr:=0x10 and R13={1DDD}   = use envelope and set envelope
  #### if rr==0b00
  # 10008888  | AAAA9999  | R8:={8888},  R9:={9999}, R10:={AAAA}  i.e. for digi sound
  # 1001rrrr  | YYYYYYYY  | Rr:={YYYYYYYY}    i.e. for R7 (mixer): 10010111-00011011
  # 10011110  | YYYYYYYY  | reserved (could be STE channel mix L^R)
  # 10011111  | YYYYYYYY  | reserved (could be STE channel mix R)

# define source code string format
# coding: utf-8

import sys
import struct
debug=0
def printdebug(s):
  if debug==1:
    print(s)

def getbytes(file,count=1):
  # returns read value as int and string
  b = bytearray(count)
  b=fid.read(count)
  str=b.decode('latin-1')   # just brute force it
  val=int.from_bytes(b, byteorder='big')    # motorola is always big
  mystr=str.replace('\n','\\n')
  printdebug(f"# got '{mystr}' 0x{val:0{count*2}x} {val}")
  return {'str': str,'int': val}

#def getbytes(file,count=1):
#  b=ord(fid.read(count))
#  print(f"got {b:02x} {b:08b} {b:3d}")
#  return b

mfp_clk = 2457600.0
mfp_div = 16
saint_quartz   =32084992
psg_clk = int(saint_quartz/4/4)   # something around 2Mhz
mfp_adjust=mfp_clk / mfp_div / psg_clk
vbl=50

fname=sys.argv[1]
registervalues="00-00-00-00-00-00-00-00-00-00-00-00-00-00".split("-")
mfp_ticks=0 
with open(fname, 'rb') as fid:
  byte=getbytes(fid,6)["str"]    # (a1)+
  # print(byte)
  if byte!="YMPKST":
    print("# Not ympkst stream")
    exit()
  byte=getbytes(fid,2)["str"]    # (a1)+
  if byte!="10":
    print("# only v1.0 supported")
    exit()
  mfpclock=getbytes(fid,4)['int'] # read 4 bytes big endian (motorola format)
  printdebug(f'# mfp clock is {mfpclock:08x} ({mfpclock:d}Hz)')
  streamlen=getbytes(fid,4)['int']  # read 4 bytes big endian (motorola format)
  printdebug(f'# len is {streamlen:08x}')
  while 1:
    b=getbytes(fid)
    if b["str"]=="":
      break
    byte=b['int']
    # decode varint
    deltaclock=0
    while byte & (1<<7):  # repeat as long as top bit is set
      deltaclock=(deltaclock+(byte & 0x7f))<<7   # add to clock and shift 1 septet
      byte=getbytes(fid)['int']
    deltaclock=deltaclock+byte
    printdebug(f'# dclock: {deltaclock:08x}') 
    byte=getbytes(fid)['int']
    if not byte & (1<<7):
      # test if it is bit array
      if byte & (1<<6):
        print("# ERROR reserved code")
        exit()
      else:
        # printdebug("#  it is 00xxxxxx so we read the second part")
        byte2=byte
        byte=getbytes(fid)['int']
        printdebug(f"# bitfield decoder start {byte2:08b} {byte:08b}")
        rnum=0
        if byte != 0:
          printdebug(f"# 01234567 bitfield {byte:08b}")
          bitn=7
          while rnum <8:
            if byte & (1<<bitn):  # bit number bitn is set, so register rnum shall be read
              value=getbytes(fid)['int']
              registervalues[rnum]=f'{value:02x}'
              printdebug(f'# got R{rnum}={value:02x}')
            rnum=rnum+1
            bitn=bitn-1
        byte=byte2
        rnum=8
        if byte != 0:
          printdebug(f"#  0089ABCD {byte:08b}")
          bitn=5
          while rnum <14:
            if byte & (1<<bitn):  # bit number bitn is set, so register rnum shall be read
              value=getbytes(fid)['int']
              registervalues[rnum]=f'{value:02x}'
              printdebug(f'# got R{rnum}={value:02x}')
            rnum=rnum+1
            bitn=bitn-1
        printdebug("# bitfield decoder end")
    else:
      # one of the short codes %1xxxxxxx
      if (byte & 0b01100000) != 0: # test for channel 1-3 %1rrxxxxx  (code100 ?)
        # get the register number
        register=((byte& 0b01100000)>>5)+7
        if (byte & 0b00010000) != 0:   # check bit S in 1rrSnnnn (volonly)
          if (byte & 0b00001000) == 0: # check bit S in 1rr1Sxxx (volenv?)
            # now it is 1rr10xxx, we only need the xxx part
            if (byte & 0b00000111) != 0: # non zero is reserved
              print("# ERROR reserved code")
              exit()
            else:
              registervalues[register]=f'{getbytes(fid,1)["int"]:02x}'
          else: # volenv
            registervalues[register]=f'{byte:02x}'    # this does not really decode to the original, but YM ignores top 3 bits
            registervalues[13]=f'{byte:02x}' 
        else:  # volonly
          printdebug(f'# set vol in {register} to {byte:02x}')
          registervalues[register]=f'{byte:02x}' # volume value (ym ignores top 3 bits)
      else:  # code100
        # data is  %100Zxxxx (10008888|9999AAAA, 1001rrrr|YYYYYYYY)
        if (byte & 0b00010000) != 0:   # check for sample
          # it is a single register 1001rrrr
          register=(byte & 0b00001111)  # get register number
          value=getbytes(fid,1)["int"]
          if register <14:   # compare if legal (not portA or portB)
            registervalues[register]=f'{value:02x}'
          else:
            print(f"# ERROR unauthorized register {value}")
            exit()
        else:  # sample
          # play typical 3 volumes digisound (modfiles)
          registervalues[8]=f'{byte:02x}'   # byte=%10008888 Ym ignores top 3 bits
          byte=getbytes(fid,1)["int"]  # read from stream %9999AAAA
          registervalues[9]=f'{(byte & 0b11110000)>>4:02x}'
          registervalues[10]=f'{byte & 0b00001111:02x}'
            
    # done decoding frame
    mfp_ticks=mfp_ticks+deltaclock
    printdebug(f'# mfp_ticks = {mfp_ticks:08x}')
    # emulate the YM
    if registervalues[1]!="..":
      registervalues[1]=f'{int(registervalues[1],16)&0x0f:02x}'  # high freqA mask
    if registervalues[3]!="..":
      registervalues[3]=f'{int(registervalues[3],16)&0x0f:02x}'  # high freqB mask
    if registervalues[5]!="..":
      registervalues[5]=f'{int(registervalues[5],16)&0x0f:02x}'  # high freqC mask
    if registervalues[6]!="..":
      registervalues[6]=f'{int(registervalues[6],16)&0x1f:02x}'  # noise mask
    if registervalues[8]!="..":
      registervalues[8]=f'{int(registervalues[8],16)&0x1f:02x}'  # volA mask
    if registervalues[9]!="..":
      registervalues[9]=f'{int(registervalues[9],16)&0x1f:02x}'  # volB mask
    if registervalues[10]!="..":
      registervalues[10]=f'{int(registervalues[10],16)&0x1f:02x}' # volC mask
    if registervalues[13]!="..":
      registervalues[13]=f'{int(registervalues[13],16)&0x0f:02x}' # shape mask
    vbl=mfp_ticks/40064/mfp_adjust
    ymclock=int(mfp_ticks/mfp_adjust)
    print(f'{int(vbl):06X} {ymclock:010X} '+"-".join(registervalues).upper())  
    registervalues="..-..-..-..-..-..-..-..-..-..-..-..-..-..".split("-")
  
