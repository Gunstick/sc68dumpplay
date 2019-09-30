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

import sys
import struct


def getbytes(file,count=1):
  b=ord(fid.read(count))
  # print(f"got {b:02x}")
  return b

mfp_clk = 2457600.0
mfp_div = 16
saint_quartz   =32084992
psg_clk = int(saint_quartz/4/4)   # something around 2Mhz
mfp_adjust=mfp_clk / mfp_div / psg_clk

fname=sys.argv[1]
registervalues="00-00-00-00-00-00-00-00-00-00-00-00-00-00".split("-")
with open(fname, 'rb') as fid:
  byte=fid.read(6)    # (a1)+
  print(byte)
  if byte!=b"YMPKST":
    print("Not ympkst stream")
    exit()
  byte=fid.read(2)    # (a1)+
  if byte!=b"10":
    print("only v1.0 supported")
    exit()
  mfpclock=struct.unpack(">i",fid.read(4))[0] # read 4 bytes big endian (motorola format)
  print(f'mfp clock is {mfpclock:08x} ({mfpclock:d}Hz)')
  streamlen=struct.unpack(">i",fid.read(4))[0]  # read 4 bytes big endian (motorola format)
  print(f'len is {streamlen:08x}')
  ymclock=0 
  a=0
  while 1:
    byte=getbytes(fid)
    # decode varint
    deltaclock=0
    while byte & (1<<7):  # repeat as long as top bit is set
      deltaclock=(deltaclock+(byte & 0x7f))<<7   # add to clock and shift 1 septet
      byte=getbytes(fid)
    deltaclock=deltaclock+byte
    
    byte=getbytes(fid)
    if byte & (1<<7):
      # one of the short codes %1xxxxxxx
      a=a
    else:
      # test if it is bit array
      if byte & (1<<6):
        print("ERROR reserved code")
        exit()
      else:
        # print(" it is 00xxxxxx so we read the second part")
        print("bitfield decoder start")
        byte2=byte
        byte=getbytes(fid)
        rnum=0
        if byte != 0:
          # print(" 01234567 bitfield")
          bitn=7
          while rnum <8:
            if byte & (1<<bitn):  # bit number bitn is set, so register rnum shall be read
              value=getbytes(fid)
              registervalues[rnum]=f'{value:02x}'
              print(f'got R{rnum}={value:02x}')
            rnum=rnum+1
            bitn=bitn-1
        byte=byte2
        rnum=8
        if byte != 0:
          # print(" 0089ABCD")
          bitn=5
          while rnum <14:
            if byte & (1<<bitn):  # bit number bitn is set, so register rnum shall be read
              value=getbytes(fid)
              registervalues[rnum]=f'{value:02x}'
              print(f'got R{rnum}={value:02x}')
            rnum=rnum+1
            bitn=bitn-1
        print("bitfield decoder end")
    ymclock=ymclock+deltaclock
    print(f'{int(ymclock/mfp_adjust):08x} '+"-".join(registervalues).upper())  

  
  
  print(f'{a} bytes')

