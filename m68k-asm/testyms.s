;;; @file    testyms.s
;;; @author  Gunstick/ULM & Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-27
;;; @brief   Program testing the decoder of the binary ym-stream format.
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	Include	"debug.i"
	Include	"ymdump.i"
	Include	"yms.i"
	Include	"xbios.i"
	Include	"start.i"

; future: asynchronous decompress and playing: set to 0
BUFFERPLAY:	SET 1

	STARTUP	main,(a7)
main:	SUPEREXEC	#superrout
	rts

tArout:	addq.l	#1,va_tacount                   ; this is called at 2400Hz
	;; eor.w	#$333,$ffff8240.w
	;; move.b	#%11011111,$fffffa0F.w	; release In-Service
	rte

superrout:

	move.w	sr,savesr		; d1: save SR
	move.w	#$2700,sr
	moveq	#15,d0
	and.b	d0,$fffffa19.w          ; test timerA
	beq.s	.timeroff

	;; Exit if timer-A appears to be running
	move.w	savesr,sr		; sr: restored
	moveq	#1,d0		; error
	rts

.timeroff:
	clr.b	$fffffa19.w		; timera::TCR=0 (Stop)   (see below where TCR is set to 1)
	clr.b	$fffffa1f.w		; timera::TDR=256
	move.l	$134.w,save134	; save Timer-A vector
	move.l	#tArout,$134.w	; install new Timer-A Vector
	bset	#5,$fffffa07.w	; enable timer-A interrupt
	bset	#5,$fffffa13.w	; unmask timer-A interrupt
	move.w	#$2300,sr		; IPL=3
	bclr	#0,$484.w		; No clicks
	bclr	#3,$fffffa17.w	; AEI


init_dmp:	;; ------------------------------------

	lea	ymsdata,a1
	bsr yms_header
	;;; in d0 is now the mfp Hz
	;;; a1 points to start of stream
	move.l	a1,va_curpos

	;; Setup init dump
	;; lea	ymdump,a0
	;; clr.l	ymdmp_clk(a0)
	;; clr.w	ymdmp_clk+4(a0)
	;; move.w	#(1<<14)-1,ymdmp_set(a0)
;; 	lea	ym_intval,a1
;; 	moveq	#13,d0
;; copy_reg:
;; 	move.b	0(a1,d0.w),ymdmp_reg(a0,d0.w)
;; 	dbf	d0,copy_reg

	lea	ymsdata(pc),a1
	move.l	a1,va_begline
	move.l	#eof,va_endpos

	clr.w	va_nxtmfph
	clr.l	va_nxtmfpl
	clr.l	va_tacount
	clr.l	va_nexttdr
	clr.l	va_nextevt

	move.b	#1,$fffffa19.w	; TimerA::TCR=1 -> start 2400-hz
	;; ------------------------------------

	;; init player
	lea     ymdump(pc),a0   ; write dump here
	lea     ymdump(pc),a2   ; read dump here
	IfEq BUFFERPLAY
	move.w  #1000,d5
	move.l  va_curpos,a1    ; read yms here
fillit: ; pre decode  frames
	bsr    yms_decode
	dbf     d5,fillit
	EndC
play_dmp:	;; ------------------------------------
	IfNe BUFFERPLAY
	lea     ymdump(pc),a2   ; read dump here
	EndC
	;; copy previous timestamp
	;; ASSERT	eq,cmpa.l,#ymdump,a0
	;; lea	ymprev-ymdump(a0),a1	; a1= ymprev
	;; move.l	ymdmp_clk+0(a0),ymdmp_clk+0(a1)
	;; move.w	ymdmp_clk+4(a0),ymdmp_clk+4(a1)
	move.w	#$070,$ffff8240.w	;
	;; get next data
	move.l	va_curpos,a1	; read yms here
	cmp.l	va_endpos,a1
	bhs	over
	bsr	yms_decode
	; a0 points after the ffff tag
	IfNe BUFFERPLAY
	lea	ymdump(pc),a0	; jump back
	EndC
	; bsr	yms_next (not needed)
	move.l	a1,va_curpos

	;; compute delta time to next event
	;; in yms we directly get the delta
	;lea	ymprev-ymdump(a0),a1	; a1= ymprev (t0)
	;bsr	ymdmp_dclock		; d0= t1-t0 (timer*128)
	move.l	(a2)+,d0	; the yms decoder immediately gives mfp ticks
	lsl.l	#8,d0	; move from gunstick to ben's world
	lsl.l	#3,d0	; move from gunstick to ben's world

	;; next event in full precision (timer*128)
	move.w	va_nxtmfph,d1
	move.l	va_nxtmfpl,d2
	add.l	d0,d2
	moveq	#0,d0
	addx.w	d0,d1		; d1:d2 nxtmfp
	move.w	d1,va_nxtmfph
	move.l	d2,va_nxtmfpl
	;; convert to timer/4 (divide by 512)
	lsr	#1,d1		; divide by 2
	roxr.l	#1,d2
	move.w	d2,va_nexttdr	; divide by 256
	move.w	d1,d2		;
	swap	d2		;
	move.l	d2,va_nextevt	;

	move.w	#$700,$ffff8240.w
	lea	$fffffc02.w,a5   ;; keyboard acia
	lea	$fffffa1f.w,a4   ;; timerA data
	lea	va_tacount,a3
	move.l	va_nextevt,d7
	moveq	#$39,d0          ;; space key
test_key:
	cmp.b	(a5),d0    ;; pressed space?
	beq	over
	;;
	cmp.l	(a3),d7
	bhi.s	test_key
	blo.s	skip_low

	move.b	va_nexttdr,d5
	beq.s	skip_low

	;;
wait_low:
	move.b	(a4),d6		; d6.b: TDR
	neg.b	d6
	cmp.b	d5,d6		;
	blo.s	wait_low		;
skip_low:
	move.w	#$777,$ffff8240.w	;

	;; commit event to YM
	;lea	ymdump+4(pc),a2
	bsr	ymsend
	;; clr.w	ymdmp_set(a0)

	bra	play_dmp
over:
	bclr	#5,$fffffa07.w	; disable timer-A interrupt
	clr.b	$fffffa19.w		; Stop timer-A
	bset	#3,$fffffa17.w	; SEI
	move.l	save134,$134.w	; restore timer-A vector
	move.w	#$777,$ffff8240.w	; restore background color
	lea	$ffff8800.w,a0	; mute YM2149
	move.l	#$08000000,(a0)	;
	move.l	#$09000000,(a0)	;
	move.l	#$0A000000,(a0)	;
	moveq	#0,d0		; no error
	rts

;;; ymsend()
;;;
ymsend:
	lea	$ffff8800.w,a6
	;move.w	ymdmp_set(a2),d0	; ?

	move.w	(a2)+,d1	; assume we at leaast have 1 value
.nextreg:
	movep.w	d1,0(a6)
	move.w	(a2)+,d1	; yms struct is just $0rvv $0rvv ...
	bpl.s .nextreg		; end when $ffff
	IfNe BUFFERPLAY
	;lea 1(a2,d1.w),a2      ; a2+1+(-1)=a2   this does
	;move.l (a2)+,a2        ; another way for jump back
	EndC
	rts

	DATA

;; ym_intval:	dc.b	0,0,0,0,0,0		; $0-$5 periods
;; 	dc.b	0,$3f,0,0,0		; $6-$a noise,mixer,volume
;; 	dc.b	0,0,0		; $b-$d envelop
	even

va_begline:	ds.l	1
va_endpos:	ds.l	1
va_curpos:	ds.l	1

va_nxtmfph:	ds.w	1
va_nxtmfpl:	ds.l	1

va_tacount:	ds.l	1
va_nextevt:	ds.l	1
va_nexttdr:	ds.w	1

save134:	ds.l	1
savesr:	ds.w	1

;; ymprev:	ds.w	3		; only need the clock
ymdump:
	Rept 500
	ds.l	1	; delta of mfp ticks
	ds.w	16	; movep data terminated by $ffff
	EndR

ymsdata:	incbin	"test.yms"
eof:
	even

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
