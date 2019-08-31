;;; @file    testcli.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-25
;;; @brief   Testing command line parser
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	Include	"start.i"

	STARTUP	main,(a7)

main:
	move.l	$4(a7),d0		; d0: argc
	move.l	$8(a7),a0		; a0: argv 
	move.l	$c(a7),a1		; a1: basepage

	lea	clistr+3,a2
	bsr	print_word
	
 	lea	clistr,a2
 	moveq	#15,d1
 	and.b	d0,d1
 	move.l	d0,d2
 	lsr	#4,d2
 	move.b	Thex(pc,d2.w),(a2)+
 	move.b	Thex(pc,d1.w),(a2)+
 	addq.w	#1,a2
	bsr	print_word

	bra.s	print_next	
print_args:	
 	lea	clistr,a2
	move.l	(a0)+,a3

	move.b	#27,(a2)+
	move.b	#"p",(a2)+		; ESC<q> (reverse video)
.copy:
	move.b	(a3)+,(a2)+
	bne.s	.copy
	bsr	print_word
print_next:	
	dbf	d0,print_args
	
	CRAWCIN	
	moveq	#0,d0
	rts

print_word:
	move.b	#27,-1(a2)
	move.b	#"q",(a2)+		; ESC<q> (normal video)
 	move.b	#$D,(a2)+		; <CR>
 	move.b	#$A,(a2)+		; <LF>
 	clr.b	(a2)		; <NUL>
	movem.l	d0-a6,-(a7)
	CCONWS	clistr
	movem.l	(a7)+,d0-a6
	rts

	;; 
	DATA
	;; 

Thex:	dc.b	"0123456789ABCDEF"
clistr:	dc.b	27,"E"		; vt52 cls
	dcb.b	128,0
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
