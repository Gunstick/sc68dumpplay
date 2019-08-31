;;; @file    testdmp.s
;;; @date    2019-09-01
;;; @author  Ben/OVR
;;; @brief   test ymdump decoder
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	Include	"ymdump.i"
	Include	"gemdos.i"

	Include	"start.i"
	
	STARTUP	main,(a7)
main:	SUPEREXEC	superrout
	rts

superrout:	
	bclr	#0,$484.w		;
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
	move.w	#$777,$ffff8240.w
	move.l	#$08000000,$ffff8800.w
	move.l	#$09000000,$ffff8800.w
	move.l	#$0A000000,$ffff8800.w
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
ymstat:	ymdmp_DS

	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
