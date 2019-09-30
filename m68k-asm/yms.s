;;; @file    yms.s
;;; @date    2019-09-27
;;; @author  Gunstick/ULM & Ben/OVR
;;; @brief   ym stream format
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

;;;
;;; sc68 YMPKST format (binary)
;;;
;;; file header
;;; offset | size | description
;;; -------|------|------------
;;;     00 |   +6 | "YMPKST" magic string
;;;     06 |   +1 | $30 ('0') + version
;;;     07 |   +1 | $30 ('0') + flags
;;;     08 |   +4 | clock (hz) big endian uint32 (currently must be 0x00025800)
;;;     12 |   +4 | data size big endian uint32 (0 if unknown)
;;;
;;; typical file starts with YMPKST10
;;;
;;; header is followed by variable length data packets
;;; each packet has a timestamp, and data
;;;
;;; ** timestamp **
;;; The timestamp represents the number of
;;; clock cycles elapsed. It's 32-bit big endian variable length
;;; unsigned integer. Similar to UTF-8 encoding the bit-7 of each byte
;;; is set when there is a following byte (0x7F encodes 127, 0x0100
;;; encode 128).
;;;
;;; ** data **
;;; There are various data possible
;;; byte-0    | byte-1    | description
;;; --------- | --------- | -----------
;;; 0089ABCD  | 01234567  | 00 + a bit set means named register is present (followed by all bytes starting at R0)
;;; 01xxxxxx  |           | reserved    (timer values perhaps?)
;;; 1rr.....  |           | quick set for volume register R(7+0brr)   01 <= rr <= 11
;;; 1rr0nnnn  |           | Rr:={0nnnn}     rr=01 => R8, rr=10 => R9, rr=11 => R10
;;; 1rr10000  |           | Rr:=0x10    = use envelope
;;; 1rr10xxx  |           | reserved
;;; 1rr11DDD  |           | Rr:=0x10 and R13={1DDD}   = use envelope and set envelope
;;; if rr==0b00
;;; 10008888  | 9999AAAA  | R8:={8888},  R9:={9999}, R10:={AAAA}  i.e. for digi sound
;;; 1001rrrr  | YYYYYYYY  | Rr:={YYYYYYYY}    i.e. for R7 (mixer): 10010111-00011011
;;; 10011110  | YYYYYYYY  | reserved (could be STE channel mix L^R)
;;; 10011111  | YYYYYYYY  | reserved (could be STE channel mix R)

;;;per register example:
;;; 1010nnnn  |           | R8:={nnnn}
;;; 10110000  |           | R8:=0x10
;;; 10110xxx  |           | reserved
;;; 10111DDD  |           | R8:=0x10 and R13:={1DDD}
;;; 1100nnnn  |           | R9:={nnnn}
;;; 11010000  |           | R9:=0x10
;;; 11010xxx  |           | reserved
;;; 11011DDD  |           | R9:=0x10 and R13:={1DDD}
;;; 1110nnnn  |           | R10:={nnnn}
;;; 11110000  |           | R10:=0x10
;;; 11110xxx  |           | reserved
;;; 11111DDD  |           | R10:=0x10 and R13:={1DDD}


	Include	"yms.i"
	Include	"debug.i"

	;; -------------------------------------

;;; yms_header() - read yms header
;;; Inp:
;;;   a1.l position in YMS data (should be on timestamp)
;;; Use:
;;;   d0/d1/a1
;;; Out:
;;;   d0.l mfp speed
;;;   d1.l len od stream
;;;   a1.l new YMS data position (start of stream)
yms_header:
	cmp.l #"YMPK",(a1)
	bne.s .headererr
	addq #4,a1
	cmp.w #"ST",(a1)
	bne.s .headererr
	addq #2,a1
	cmp.w #"10",(a1)   ; we only support v1.0	
	bne.s .headererr
	addq #2,a1
	move.l (a1)+,d0		; get mfp clock into return
	move.l (a1)+,d1		; get stream leng in d1
	rts
.headererr
	illegal   ; yeah, lol

;;; yms_decode() - Decode YMS 
;;;
;;; Inp:
;;;   a0.l ym register dump area to write to
;;;   a1.l position in YMS data (should be on timestamp)
;;; Use:
;;;   d0/d1/a0/a1
;;; Out:
;;;   a0.l end of position of last write
;;;   a1.l new position in YMS data (should be on timestamp)
;;;
;;; ym register dump area: 
;;;   mfp_ticks:L   $nnnnnnnn
;;;   YM register data (max rept 15)  {$0rvv ...} $ffff
;;;
yms_decode:
	;; Get clock
	moveq	#0,d0
	moveq	#0,d1

	;; Clock is varint beteen 1 and 4 bytes
        ;; end of varint is marked by top bit = 0
	;; 0x111 => 0x80 + 0x11 = 0x911
	;; 0x977d => 0x17*0x80 + 0x7d = 0x0b80 + 0x7d = 0x0bfd
	;; 0x818f6d => 0x47ed
.clock:
	move.b	(a1)+,d0	; get varint
	bpl .lastclock 		; if no high bit, then end  
	and.b #$7f,d0		; clear top bit
	add.b d0,d1		; add to result
	lsl.l #7,d1		; move to make room for next
	bra.s .clock
.lastclock
	add.b	d0,d1		; add last to get end clock result
	move.l	d1,(a0)+	; write out mfp ticks to wait

;;; now we analyse the data. we usually have 1 byte, sometimes 2
;;; the result is written into a move.l array 'yms_struct'
;;; $0r00vv00    write into register r the value vv
;;; $0r00vv00
;;; ...
;;; $ffxxxxxx    negative number indicates end (there is no register ff)
;;; we force that R7 has always top 2 bits as 1 (port A & B output)
	
;; decoding can be speed up be using lsl #1 instead of btst, but it is less clear

	moveq	#0,d0
	move.b (a1)+,d0		; get data
	;; now we have to decide which type it is
	bmi	.short		; one of the short codes %1xxxxxxx
	;; it is 0sxxxxxx
	btst #6,d0		; test if it is bit array
	;;; 3F = 00111111
	;;;      76543210
	bne	.endregisters	; reserved
	;; it is 00xxxxxx
        ;; so we read the second part
	; first a macro...
WRITEREG:	Macro ; \1:Num
	add.b d0,d0		; lsl #1
	bcc.s .nextreg\@	; not written
	move.b #\1,(a0)+	; reg number
	move.b (a1)+,(a0)+ 	; reg value
.nextreg\@
	EndM

	swap	d0		; save 2nd part bitfield
	move.b (a1)+,d0		; 01234567 bitfield
	beq.s	.nolowregs	; little speedup
	;; do registers 0-6
I:	SET	0
	Rept	7
	WRITEREG I
I:	SET	I+1
	EndR
	;; special treatment for reg7
	add.b d0,d0		; lsl #1
	bcc.s .nolowregs	; not written
	move.b #7,(a0)+	; reg number 7
	move.b (a1)+,d0 	; reg value
	or.b #$c0,d0		; force top 2 bits to 1
	move.b d0,(a0)+ 	; reg value
.nolowregs:
	swap d0			; restore 2nd part bitfield
	add.b d0,d0
	beq.s	.nohighregs 	; very little speedup
	add.b d0,d0
	;; do registers 8-13
I:	SET	8
	Rept	6
	WRITEREG I
I:	SET 	I+1
	EndR
.nohighregs:
	bra.s .endregisters	

.short
	;; we come here if data is %1rrxxxxx
	move.l	d0,d1		; copy
	and.b	#%01100000,d1	; mask out register number
	beq.s	.code100	; rr=00: not a volume register set
	rol.b	#3,d1		; lsr #5
	add.b	#7,d1		; registers 8,9,10 (volume)
	;; now check d0 for 1rrSnnnn
	btst #4,d0	; check bit S 
	beq.s	.volonly	; it's %1rr0nnnn
	;; 1rr1Sxxx
	btst.b #3,d0		; check bit S
	bne.s	.volenv		; 1rr11DDD 
	; now it is 1rr10xxx, we only need the xxx part
	and.b #%00000111,d0	; mask out
	bne.s	.endregisters	; non zero xxx is reserved
	move.b d1,(a0)+	; volume register number
	move.b d0,(a0)+	; switch envelope on
	bra.s .endregisters

.volenv	; d1 is the register number
	move.b  d1,(a0)+	; register number (8,9,10)
	move.b	d0,(a0)+	; volume value (ym ignores top 3 bits)
	move.b	#13,(a0)+	; select shape register
	move.b	d0,(a0)+	; set shape to 1ddd
.volonly	; we got 1rr0nnnn with in d1 register number
	move.b  d1,(a0)+	; register number (8,9,10)
	move.b  d0,(a0)+	; volume value (ym ignores top 3 bits)
	bra.s	.endregisters

.code100
	;;; data is %100Zxxxx (10008888|9999AAAA, 1001rrrr|YYYYYYYY)
	btst #4,d0	; test the Z bit position	
	beq.s	.sample
	; it is a single register 1001rrrr
	and.b #$f,d0	; get register number
	move.b (a1)+,d1	; get value
	cmp.b #14,d0	; compare if legal (not portA or portB)
	bge.s	.endregisters	; reserved
	move.b d0,(a0)+
	move.b d1,(a0)+
	bra.s .endregisters

.sample	; play typical 3 volumes digisound (modfiles)
	move.b #8,(a0)+	; volA
	; d0=%10008888
	;and.b #$0f,d0	; not needed as Ym ignores top nibble
	move.b d0,(a0)+	; valueA
	move.b (a1)+,d0	; read from stream %9999AAAA
	move.b #10,(a0)+ ; volC
	move.b d0,(a0)+	; valueC (YM ignores reg9 part)
	lsr.b #4,d0	; shift reg9 part down
	move.b #9,(a0)+ ; volB
	move.b d0,(a0)+ ; valueB
	;bra.s .endregisters


.endregisters
	move.w	#-1,(a0)+	; end of registers


	rts

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
