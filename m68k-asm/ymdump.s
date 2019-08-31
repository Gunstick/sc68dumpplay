;;; @file    ymdump.s
;;; @date    2019-08-24
;;; @author  Ben/OVR
;;; @brief   ymdump line format
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

;;;
;;; sc68 YM dumps format (all number are hexadecimal)
;;;
;;; +-------------------------------------------------------------+
;;; | 0               1               2               3           |
;;; | 0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789A |
;;; |-------|----------|------------------------------------------|
;;; | PASS-#|CLK-STAMP |R0 R1 R2 R3 R4 R5 R6 R7 R8 R9 RA RB RC RD |
;;; |-------|----------|------------------------------------------|
;;; | ...... .......... FF-0F-FF-0F-FF-0F-..-..-0D-..-..-..-..-.. |
;;; +-------------------------------------------------------------+
;;;
	
	Include	"ymdump.i"

	;; -------------------------------------

ymdmp_next:
	moveq	#32,d0
	moveq	#59,d1
.next0:
	cmp.b	(a1)+,d0
	dbge	d1,.next0
	blt.s	.fail

.next1:
	cmp.b	(a1)+,d0
	dblt	d1,.next1
	bge.s	.fail
	subq.w	#1,a1
	moveq	#0,d0
	rts
.fail:
	moveq	#-1,d0
	rts

;;; ymdmp_decode() - Decode YM ASCII dump
;;;
;;; Inp:
;;;   a0.l ymdmp struct
;;;   a1.l dump string to decode
;;; Use:
;;;   d0-d7/a2
;;;
ymdmp_decode:
	lea	Xtable(pc),a2	; a2= hexa fast table
	moveq	#$0F,d7		; d7= $0F
	move.l	d7,d6		;
	not.b	d6		; d6= $F0

	;; Get clock
	addq	#7,a1		; skip pass number
	moveq	#0,d0

	;; Clock is 10 hexa digit -> 5 bytes -> 1 byte and 2 words
	moveq	#3-1,d5
.clock:
	move.b	(a1)+,d0		; d0= clock[9]
	move.b	-48(a2,d0.w),d1	; d1= $xxAA
	and.w	d6,d1		; d1= $00A0
	move.b	(a1)+,d0		; d0= clock[8]
	move.b	-48(a2,d0.w),d2	; d2= $xxBB
	and.w	d7,d2		; d2= $000B
	or.w	d2,d1		; d1= $00AB
	move.w	d1,(a0)+		; * ymdmp_clk

	Rept	2
	;; ------------------------------------
	move.b	(a1)+,d0		; d0= clock[7/3]
	move.b	-48(a2,d0.w),d1	; d1= $xxAA
	and.w	d6,d1		; d1= $00A0
	move.b	(a1)+,d0		; d0= clock[6/2]
	move.b	-48(a2,d0.w),d2	; d2= $xxBB
	and.w	d7,d2		; d2= $000B
	or.w	d2,d1		; d1= $00AB
	move.b	d3,(a0)+		; * ymdmp_clk
	;;

	
	move.b	(a1)+,d0		; d0= clock[5/1]
	move.b	-48(a2,d0.w),d3	; d3= $CC
	and.b	d6,d3		; d3= $C0
	move.b	(a1)+,d0		; d0= clock[4/0]
	move.b	-48(a2,d0.w),d2	; d2= $DD
	and.w	d7,d2		; d2= $0D
	or.b	d2,d3		; d3= $CD
	move.b	d3,(a0)+		; * ymdmp_clk
	;; ------------------------------------
	EndR

	moveq	#0,d4		; d5= ymdmp_set
	moveq	#".",d3		; d3= '.' (speed up)

ONEREG:	Macro ; \1:reg-#
	;; ------------------------------------
	move.b	1+\1*3(a1),d0	; d0= "A"
	cmp.b	d3,d0		; is "-" ?
	beq.s	.next\@		;
	bset	#\1,d4		; mark register has *set*
				;
	move.b	-48(a2,d0.w),d1	; d1= $xxAA
	and.w	d6,d1		; d1= $00A0
	move.b	2+\1*3(a1),d0	; d0= "B"
	move.b	-48(a2,d0.w),d2	; d2= $xxBB
	and.w	d7,d2		; d2= $000B
	or.b	d1,d2		; d2= $00AB
	move.b	d2,2+\1(a0)		; * ymdmp_reg[d4]
.next\@:				;
	;; ------------------------------------
	EndM

R:	Set	0
	Rept	14
	;; ------------------------------------
	ONEREG	R		;
R:	Set	R+1		;
	;; ------------------------------------
	EndR
	move.w	d4,(a0)		; * ymdmp_set
	subq	#ymdmp_set,a0	; a0= ymdmp struct
	lea	3*14(a1),a1		; a1= next line

	rts

;;; Fast hexa table indexed from "0"/$30/48
Xtable:
	dc.b $00,$11,$22,$33,$44,$55,$66,$77,$88,$99
	dc.b $00,$00,$00,$00,$00,$00,$00
	dc.b $AA,$BB,$CC,$DD,$EE,$FF

	;; GB: Normally we don't need the lower case letters
	;; dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	;; dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	;; dc.b $AA,$BB,$CC,$DD,$EE,$FF

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
