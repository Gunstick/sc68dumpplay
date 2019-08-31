;;; @file    ymplay.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-24
;;; @brief   sc68 YM dumps player 
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	Include	"start.i"

	STARTUP	main,ustack,a0

main:
	move.l	$4(a7),d0		; d0: argc
	move.l	$8(a7),a0		; a0: argv 
	move.l	$c(a7),a1		; a1: basepage

	;; cls
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

Thex:	dc.b	"0123456789ABCDEF"
clistr:	dc.b	27,"E"		; vt52 cls
	ds.b	128
omask:	dc.b	"*.dmp",0
	even

	
	;; init GEM/AES
	bsr	aes_init	; Setup GEM/AES
	lea	omask(pc),a0	; "*.dmp"
	bsr	aes_mask	; Setup fileselector mask


;;; *******************************************************

;; 	;; Save A7 and SR for clean exit
;; 	lea	stack_data(pc),a0
;; 	move	sr,(a0)+
;; 	move.l	a7,(a0)+
;; 	move.l	d0,(a0)+

;; 	;; Set supervisor stack
;; 	lea	sstack(pc),a7

;; 	;; Save ST status
;; 	bsr	save_st
	

;; 	;; Restore ST status
;; 	bsr	rest_st
	
;; 	;; Back to user mode
;; 	lea	stack_data(pc),a0
;; 	move.w	(a0)+,sr
;; 	move.l	(a0)+,a7
;; 	rts

;; ;;; *******************************************************

;; save_st:
;; 	rts

;; rest_st:
;; 	rts
	
;;; *******************************************************
;;; *******************************************************

	SECTION BSS

;;; *******************************************************
;;; *******************************************************

exitcode:
	ds.w	1
	
	;; Our stacks
	even
	ds.l	64
ustack:	ds.l	1
	ds.l	511
sstack:	ds.l	1
	

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
