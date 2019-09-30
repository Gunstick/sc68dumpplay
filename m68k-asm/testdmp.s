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

;;; ----------------------------------------------------------------------
;;;  Convert Dumps
;;; ----------------------------------------------------------------------

main:
	;; Pre-convert dumps to something faster
	lea	ymdump,a0		; a0: ymdump struct
	lea	line,a1		; a1: ascii dump
	lea	eof,a6		; a6: eof
	lea	store,a5		; a5: store
	clr.w	va_nxtmfph
	clr.l	va_nxtmfpl
	clr.w	ymprev
	clr.l	ymprev+2

x:
precode:
	;; Copy previous timestamp
	ASSERT	eq,cmpa.l,#ymdump,a0
	move.l	ymdmp_clk+0(a0),ymprev
	move.w	ymdmp_clk+4(a0),ymprev+4

	;; Decode line
	bsr	ymdmp_decode
	bsr	ymdmp_next

	;; Compute delta clock
	pea	(a1)
	lea	ymprev,a1		; a1= ymprev (t0)
	ASSERT	eq,cmpa.l,#ymdump,a0
	bsr	ymdmp_dclock		; d0= t1-t0 (timer*128)
	move.l	(a7)+,a1
	
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

	;; Store this event time
	move.w	d2,d3
	move.w	d1,d2
	swap	d2
	move.l	d2,(a5)+
	move.w	d3,(a5)+
	addq.w	#2,a5		; skip jump offset

	moveq	#0,d5		; d5: reg num
	move.l	a5,a4		; a4: start of frame
	move.w	ymdmp_set(a0),d0	; bit field
	tst.b	d0
	bne.s	.loop

	;; skip registers {0-7} if unused
	moveq	#8,d5
	moveq	#0,d0
	move.b	ymdmp_set(a0),d0
	
.loop:	;;
	lsr.w	#1,d0
	bcc.s	.next
	move.b	d5,(a5)		; GB: could optimize that
	move.b	ymdmp_reg(a0,d5.w),2(a5)
	addq.w	#4,a5 
.next:	;;
	addq.w	#1,d5
	tst.w	d0
	bne.s	.loop
	;;
	move.l	a5,d5
	sub.l	a4,d5		; 4 bytes stored per register
	lsr.w	#1,d5		; 2 instruction bytes per register
	neg.w	d5		; jump is backward
	move.w	d5,-(a4)		; * store jump offset

	;; compute delta time to next event
	ASSERT	eq,cmpa.l,#eof,a6
	cmp.l	a6,a1
	blo	precode
	ASSERT	eq,cmp.l,a6,a1
	move.l	a5,va_eof
b:
;;; ----------------------------------------------------------------------
;;;  Main
;;; ----------------------------------------------------------------------
	
	SUPEREXEC	#superrout
	rts

tArout:	addq.l	#1,va_tacount
	;; eor.w	#$333,$ffff8240.w
	;; move.b	#%11011111,$fffffa0F.w	; release In-Service
	rte

superrout:
	move.w	#$2700,sr
	moveq	#15,d0
	and.b	d0,$fffffa19.w
	beq.s	.timeroff

	;; Exit if timer-A appears to be running
	move.w	#$2300,sr		; sr: restored
	moveq	#1,d0		; error
	rts

.timeroff:
	clr.b	$fffffa19.w		; timera::TCR=0 (Stop)
	;; clr.b	$fffffa1f.w		; timera::TDR=256
	;; move.b	#128,$fffffa1f.w	; timera::TDR=128
	move.b	#64,$fffffa1f.w	; timera::TDR=64
	
	move.l	$134.w,save134	; save Timer-A vector
	move.l	#tArout,$134.w	; install new Timer-A Vector
	move.l	$fffffa06.w,savea06	; save iena
	move.l	$fffffa12.w,savea12	; save imsk

	;; Stop all mfp irqs but timer-a
	moveq	#$20,d0
	swap	d0
	move.l	d0,$fffffa06.w	;
	move.l	d0,$fffffa12.w	;

	;; bset	#5,$fffffa07.w	; enable timer-A interrupt
	;; bset	#5,$fffffa13.w	; unmask timer-A interrupt
	
	move.w	#$2300,sr		; IPL=5 (mfp only)
	bclr	#0,$484.w		; No clicks
	bclr	#3,$fffffa17.w	; AEI


init_dmp:	;; ------------------------------------

	;; Setup init dump
	clr.w	va_nxtmfph
	clr.l	va_nxtmfpl
	clr.l	va_tacount

	;; ------------------------------------

play_dmp:	;; ------------------------------------
	lea	$ffff8800.w,a6
	lea	$fffffc02.w,a5
	lea	$fffffa1f.w,a4
	lea	va_tacount,a3
	move.l	va_eof,a2
	lea	store,a0
	moveq	#$39,d0

	move.b	#3,$fffffa19.w	; TimerA::TCR=3 -> 153600/TDR
play_loop:
  	move.w	#$522,$ffff8240.w

	move.l	(a0)+,d7		; read event clock
	move.b	(a0)+,d6		;
	lsr	#2,d6		; 256->64
	
.test_key:
	;; cmp.b	(a5),d0		; <SPACE> ?
	cmp.b	#$39,$fffffc02.w
	beq	over

	;; d6.b: TDR goal
	;; d7.l: tacount goal

.resync:	;; GB: Ugly loop to be sure TDR and Counter are in sync.
	;; The idea is that if a timer interrupt has occured the TDR
	;; has loop

	move.l	(a3),d3		; Counter
	move.b	(a4),d1		; TDR
	move.l	(a3),d4		; Counter again
	cmp.w	d4,d3
	bne.s	.resync
	
	cmp.l	d3,d7		; reach ta_count ?
	beq.s	.himatch
	blo.s	.synced		; we are late already !
	bhi.s	.test_key
.himatch:
	not.b	d1		; 0->FF 1->FE ... $3F->C0
	addq.b	#1,d1		; 0->0 1->FF ...
	beq.s	.resync		; GB: not sure what to do so let's resync
	and	#63,d1
	cmp.b	d6,d1
	blo.s	.resync

.synced:
	move.w	#$777,$ffff8240.w
	addq.w	#1,a0

	move.w	(a0)+,d7
	jmp	ymtower(pc,d7.w)
	Rept	14
	move.l	(a0)+,(a6)
	EndR
ymtower:	
	cmpa.l	a2,a0
	blo	play_loop
	ASSERT	eq,cmpa.l,a0,a2

over:
	clr.b	$fffffa19.w		; Stop timer-A
	move.w	#$2700,sr
	move.l	savea06,$fffffa06.w
	move.l	savea12,$fffffa12.w
	;; bclr	#5,$fffffa07.w	; disable timer-A interrupt

	bset	#3,$fffffa17.w	; SEI
	move.l	save134,$134.w	; restore timer-A vector
	move.w	#$777,$ffff8240.w	; restore background color
	lea	$ffff8800.w,a0	; mute YM2149
	move.l	#$08000000,(a0)	;
	move.l	#$09000000,(a0)	;
	move.l	#$0A000000,(a0)	;
	stop	#$2300
	moveq	#0,d0		; no error
	rts

	
	DATA

va_eof:	ds.l	1
va_tacount:	ds.l	1
va_nxtmfph:	ds.w	1
va_nxtmfpl:	ds.l	1

savea06:	ds.l	1
savea12:	ds.l	1
save134:	ds.l	1

ymprev:	ds.w	3		; only need the clock
ymdump:	ymdmp_DS

store:	ds.b	2048
line:	incbin	"test.dmp"
eof:
	even

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
