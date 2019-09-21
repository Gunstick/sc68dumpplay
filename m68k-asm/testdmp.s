;;; @file    testdmp.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   Program testing the ymdump decoder.
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	Include	"ymdump.i"
	Include	"xbios.i"
	Include	"start.i"
	
	STARTUP	main,(a7)
main:	SUPEREXEC	#superrout
	rts

tArout:	addq.l	#1,cnt2400
	eor.w	#$333,$ffff8240.w
	move.b	#%11011111,$fffffa0F.w	; release In-Service
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
	move.b	#1,$fffffa19.w	; TimerA::TCR=1 -> start 2400-hz
	move.w	#$2300,sr		; IPL=3
	
	bclr	#0,$484.w		; No clicks
	move.l	$4ba.w,hz200
	lea	ymstat,a0
	move.l	#eof,a1

loop:	cmpa.l	#eof,a1
	blo.s	.ok
	lea	line,a1
.ok:
	jsr	ymdmp_decode

	clr.w	$ffff8240.w
wait:
	cmp.b	#$39,$fffffc02.w
	beq.s	over
	move.l	$4ba.w,d0
	cmp.l	hz200,d0
	bls.s	wait
	addq.l	#3,d0
	move.l	d0,hz200
	move.w	#$777,$ffff8240.w

	jsr	ymsend
	jsr	ymdmp_next
	bne.s	over
	bra.s	loop

over:
	bclr	#5,$fffffa07.w	; disable timer-A interrupt
	clr.b	$fffffa19.w		; Stop timer-A
	move.l	save134,$134.w		; Restore timer-A vector
	move.w	#$777,$ffff8240.w	; restore background color
	lea	$ffff8800.w,a0	; mute YM2149
	move.l	#$08000000,(a0)	;
	move.l	#$09000000,(a0)	;
	move.l	#$0A000000,(a0)	;
	moveq	#0,d0		; no error
	rts

ymsend:
	lea	$ffff8800.w,a6
	move.w	ymdmp_set(a0),d0

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
	EndM

I:	SET	0
	Rept	14
	SENDREG	I
I:	SET	I+1
	EndR

	rts

	DATA

line:	incbin	"lap27.dmp"
eof:	
	even

	BSS
hz200:	ds.l	1
save134:	ds.l	1
savesr:	ds.w	1
cnt2400:	ds.l	1

ymstat:	ymdmp_DS

	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
