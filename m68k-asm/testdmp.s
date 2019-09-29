;;; @file    testdmp.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   Program testing the ymdump decoder.
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	Include	"debug.i"
	Include	"ymdump.i"
	Include	"xbios.i"
	Include	"start.i"

	STARTUP	main,(a7)
	illegal			; GB: just for sourcer68
	bra.w	superrout		;
main:	SUPEREXEC	#superrout
	rts

tArout:	addq.l	#1,va_tacount
	;; eor.w	#$333,$ffff8240.w
	;; move.b	#%11011111,$fffffa0F.w	; release In-Service
	rte

superrout:

	move.w	sr,savesr		; d1: save SR
	move.w	#$2700,sr
	moveq	#15,d0
	and.b	d0,$fffffa19.w
	beq.s	.timeroff

	;; Exit if timer-A appears to be running
	move.w	savesr,sr		; sr: restored
	moveq	#1,d0		; error
	rts

.timeroff:
	clr.b	$fffffa19.w		; timera::TCR=0 (Stop)
	clr.b	$fffffa1f.w		; timera::TDR=256
	move.l	$134.w,save134	; save Timer-A vector
	move.l	#tArout,$134.w	; install new Timer-A Vector
	bset	#5,$fffffa07.w	; enable timer-A interrupt
	bset	#5,$fffffa13.w	; unmask timer-A interrupt
	move.w	#$2300,sr		; IPL=3
	bclr	#0,$484.w		; No clicks
	bclr	#3,$fffffa17.w	; AEI


init_dmp:	;; ------------------------------------

	;; Setup init dump
	lea	ymdump,a0
	clr.l	ymdmp_clk(a0)
	clr.w	ymdmp_clk+4(a0)
	move.w	#(1<<14)-1,ymdmp_set(a0)
	lea	ym_intval,a1
	moveq	#13,d0
copy_reg:
	move.b	0(a1,d0.w),ymdmp_reg(a0,d0.w)
	dbf	d0,copy_reg

	lea	line(pc),a0
	move.l	a0,va_begline
	move.l	a0,va_curline
	move.l	#eof,va_endline

	clr.w	va_nxtmfph
	clr.l	va_nxtmfpl
	clr.l	va_tacount
	clr.l	va_nexttdr
	clr.l	va_nextevt

	move.b	#1,$fffffa19.w	; TimerA::TCR=1 -> start 2400-hz
	;; ------------------------------------

play_dmp:	;; ------------------------------------
	move.w	#$700,$ffff8240.w
	moveq	#$39,d0
	lea	$fffffc02.w,a5
	lea	$fffffa1f.w,a4
	lea	va_tacount,a3
	move.l	va_nextevt,d7
test_key:
	cmp.b	(a5),d0
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
	lea	ymdump(pc),a0
	bsr	ymsend
	clr.w	ymdmp_set(a0)

	;; copy previous timestamp
	ASSERT	eq,cmpa.l,#ymdump,a0
	lea	ymprev-ymdump(a0),a1	; a1= ymprev
	move.l	ymdmp_clk+0(a0),ymdmp_clk+0(a1)
	move.w	ymdmp_clk+4(a0),ymdmp_clk+4(a1)

	;; get next line
	move.l	va_curline,a1
	cmp.l	va_endline,a1
	bhs	over
	bsr	ymdmp_decode
	bsr	ymdmp_next
	move.l	a1,va_curline

	;; compute delta time to next event
	lea	ymprev-ymdump(a0),a1	; a1= ymprev (t0)
	bsr	ymdmp_dclock		; d0= t1-t0 (timer*128)

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

SENDREG:	Macro ; \1:Num
	lsr	d0
	bcc.s	.skip\@
	;;
	IfEQ	\1-7
	move.w	sr,-(a7)
	move.w	#$2700,sr
	moveq	#-64,d1
	move.b	#7,(a6)
	and.b	(a6),d1
	or.b	\1+ymdmp_reg(a0),d1
	move.b	d1,2(a6)
	move.w	(a7)+,sr
	;;
	Else
	;;
	move.w	#\1*256,d1
	move.b	\1+ymdmp_reg(a0),d1
	movep.w	d1,0(a6)
	;;
	EndC
.skip\@:
	EndM	; SENDREG
	
VOLSEND:	Macro ; \1:volume register
	move.w	#\1*256,d1		; 4 bytes
	move.b	\1+ymdmp_reg(a0),d1	; 4 bytes
	movep.w	d1,0(a6)		; 4 bytes
	rts			; 2 byte
	nop			; 2 bytes => 16 bytes
	EndM	; VOLSEND

GENERAL:	Macro
	bra.s	.general
	dcb.w	7,$4e71
	EndM	; GENERAL

	
ymsend:
	lea	$ffff8800.w,a6
	move.w	ymdmp_set(a0),d0

	cmp.w	#1<<13,d0
	bne.s	.not_buzz

	;; Buzz only
	move.w	#$0D00,d1
	move.b	ymdmp_reg+$D(a0),d1
	movep.w	d1,0(a6)
	rts
	
.not_buzz:
	move.w	#%111<<8,d1
	and.w	d0,d1
	cmp.w	d0,d1
	bne	.general
	lsr	#4,d1
	jmp	.fastsend(pc,d1.w)

.fastsend:
	rts			; 0
	dcb.w	7,$4e71
	VOLSEND	$8		; 1
	VOLSEND	$9		; 2
	GENERAL			; 3
	VOLSEND	$A		; 4
	GENERAL			; 5
	GENERAL			; 6
	GENERAL			; 7

.general:
	
I:	SET	0
	Rept	14
	SENDREG	I
I:	SET	I+1
	EndR

	rts

	DATA

ym_intval:	dc.b	0,0,0,0,0,0		; $0-$5 periods
	dc.b	0,$3f,0,0,0		; $6-$a noise,mixer,volume
	dc.b	0,0,0		; $b-$d envelop
	even

va_begline:	ds.l	1
va_endline:	ds.l	1
va_curline:	ds.l	1

va_nxtmfph:	ds.w	1
va_nxtmfpl:	ds.l	1

va_tacount:	ds.l	1
va_nextevt:	ds.l	1
va_nexttdr:	ds.w	1

save134:	ds.l	1
savesr:	ds.w	1

ymprev:	ds.w	3		; only need the clock
ymdump:	ymdmp_DS

line:	incbin	"test.dmp"
eof:
	even

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
