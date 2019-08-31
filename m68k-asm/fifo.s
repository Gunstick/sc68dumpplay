;;; @file    fifo.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-25
;;; @brief   A simple fifo
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	include	"fifo.i"

;;; ----------------------------------------------------------------------
;;;
;;; fifo_size() - Get FIFO buffer size
;;;
;;; < a0.l fifo struct
;;; > d0.l fifo buffer size
;;;

fifo_size:
	move.w	fifo_len(a0),d0
	ext.l	d0
	rts


;;; ----------------------------------------------------------------------
;;;
;;; fifo_used() - Get FIFO used space
;;;
;;; < a0.l fifo struct
;;; > d0.l fifo used bytes
;;; # d1.w
;;;

fifo_used:
	move.l	fifo_RW(a0),d0	; d0=R|W
	bmi.s	fifo_size		; if full return size
				;
	swap	d0		; Swapping the index ...
	bra.s	fifo_comm		; ... and continue

;;; ----------------------------------------------------------------------
;;;
;;; fifo_free() - Get FIFO free space
;;;
;;; < a0.l fifo struct
;;; > d0.l fifo free bytes
;;; # d1.w
;;;

fifo_free:
	move.l	fifo_RW(a0),d0	; d0=R|W
	bmi.s	fifo_full		; if full return 0
fifo_comm:
	move.w	d0,d1		; d1=W
	clr.w	d0		; d0=R|0
	swap	d0		; d0=0|R
	sub.w	d1,d0		; d0=R-W=free
	bpl.s	.skip
	add.w	fifo_len(a0),d0
.skip:
	rts
fifo_full:
	moveq	#0,d0
	rts

;;; ----------------------------------------------------------------------
;;;
;;; fifo_push(buf,len) - Push length byte into the fifo (no check)
;;;
;;; < a0.l fifo struct
;;; < a1.l buffer
;;; < d0.w length (>0)
;;; > a0.l buffer+length
;;; > d0.w -1
;;; # d1.w, d2.w, a1.l
;;;
fifo_push:
	rts

;;; ----------------------------------------------------------------------
;;;
;;; fifo_pull(buf,len) - Pull length byte out of the fifo (no check)
;;;
;;; < a0.l fifo struct
;;; < a1.l buffer
;;; < d0.w length
;;; > a0.l buffer+length
;;; > d0.w -1
;;; # d1.w, d2.w, a1.l
;;;

fifo_pull:
	move.l	fifo_RW(a0),d1	; d1= R|W
	move.w	d1,d2		; d2= W
	swap	d1		; d1= R
	lea	fifo_buf(a0,d1.w),a2	; a2= fifo read ptr
	;; 
	cmp.w	d1,d2		; W ? R
	bge.s	.maybe_2parts

	;; 1 part copy
	add.w	d0,d1		; R+

	;; Part-2
.part2:				;
	lsr	#1,d0		; in words
	subq	#1,d0		; dbf adjust
.copy2:				;
	move.w	(a2)+,(a1)+		;
	dbf	d0,.copy2		;
	move.w	d1,fifo_R(a0)	; * fifo_R <= d1
	rts			;
	;; ------------------------------------


.maybe_2parts:	
	move.w	fifo_len(a0),d3	; d3= size

	add.w	d0,d1		; d1= R+
	cmp.w	d3,d1		; R+ ? Sz
	blt.s	.part2
	sub.w	d3,d1		; d1= R+ (modulo size)
	beq.s	.part2		;
	sub.w	d1,d0		;
.part1:				;
	lsr	#1,d0		; in words
	subq	#1,d0		; dbf adjust
.copy1:				;
	move.w	(a2)+,(a1)+		;
	dbf	d0,.copy1		;
	
	lea	fifo_buf(a0),a2	; a2= fifo_buf
	move.w	d1,d0		; d1= R+
	;; ------------------------------------
	bra.s	.part2		;

;; init:
;;	move.l	$134.w,save134
;;	clr.b	$fffffa19.w	; Stop timer A
;;	clr.b	$fffffa1f.w	; Maximum predivision (256 counts)
;;	bset	#5,$fffffa13.w	; unmask
;;	bset	#5,$fffffa07.w	; enable

;;	move.l	#timerA_int,$134.w


;; ;;; < a0.l ymstat struct
;; ;;; < a1.l ymdump line
;; ;;;


;; ymdmp_decode:







;; ;;; Timer A routine just count
;; ;;;
;; ;;;
;; timerA_int:
;;	addq.l	#1,mfp1024
;;	rte


;; save134:	ds.l	1
;; mfp1024:	ds.l	1

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
