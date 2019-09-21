;;; @file    ibuffer.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-02
;;; @brief   Input Stream Buffer
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	include	"ibuffer.i"
	include	"ifread.i"

	xdef	isb_init
	xdef	isb_open,isb_close,isb_read
	xdef	isb_rewind,isb_tell
	
;;; ----------------------------------------------------------------------
;;;
;;; isb_Init() - Setup buffer
;;;
;;; < a0.l buffer
;;; < a1.l ibs
;;; < d0.l max
;;;

isb_init:	;; ------------------------------------,
	move.l	a1,isb_inp(a0)	;
	move.l	d0,isb_max(a0)	;
	clr.l	isb_len(a0)		;
	clr.l	isb_idx(a0)		;
	;; ------------------------------------`
	rts
	
;;; ----------------------------------------------------------------------
;;;
;;; isb_open() - Reset buffer and open underlying input stream
;;;
;;; < a0.l isb
;;; > d0.l error
;;; sr#N   set on error

isb_open:	;; ------------------------------------,
	pea	(a1)		;
	pea	(a0)		;
	clr.l	isb_len(a0)		;
	clr.l	isb_idx(a0)		;
	movea.l	isb_inp(a0),a1	;
	exg	a0,a1		; a0: inp
	movea.l	if_open(a0),a1	; a1: open()
	jsr	(a1)		;
	move.l	(a7)+,a0		;
	move.l	(a7)+,a1		;
	;; ------------------------------------`
	rts

;;; ----------------------------------------------------------------------
;;;
;;; isb_close() - Reset buffer and close underlying input stream
;;;
;;; < a0.l buffer
;;; > d0.l error
;;; > sr#N set on error

isb_close:	;; ------------------------------------,
	clr.l	isb_len(a0)		;
	clr.l	isb_idx(a0)		;
	move.l	isb_inp(a0),a1	;
	move.l	a0,a6		;
	exg	a0,a1		; a0: iface
	move.l	if_close(a0),a1	; a1: close()
	jsr	(a1)		;
	move.l	a6,a0		;
	;; ------------------------------------`
	rts
	
;;; ----------------------------------------------------------------------
;;;
;;; isb_read() - Read from buffer
;;;
;;; < a0.l buffer
;;; < a1.l destination
;;; < d0.l 
;;; > a1.l data location (can be copied or reference into the buffer)
;;; > d0.l count
	
isb_read:	;; ------------------------------------,
	move.l	d0,d2		; d2: count
	beq.s	.exit		;
	move.l	isb_len(a0),d1	; d1: in buffer
	bne.s	.not_empty		;
	;; Replenish buffer		;
	jsr	isb_fill
	move.l	d0,d1
	ble	.exit
.not_empty:	
	cmp.l	d2,d1
	bmi.s	.need_copy
	;; 
	sub.l	d2,d1		; d1: rem
	move.l	d1,isb_len(a0)	; * isb_len
	move.l	isb_idx(a0),d1
	lea	isb_dat(a0,d1.l),a1	; * a1 data
	add.l	d2,d1		; d1: idx
	move.l	d1,isb_idx(a0)	; * isb_idx
	move.l	d2,d0
.exit:
	rts

.need_copy:
	sub.l	d1,d2		; count after this copy
	move.l	a1,a2		; a2: dst ptr
.loop:
	move.l	isb_idx(a0),d0
	lea	isb_dat(a0,d0.l),a3	; a3: src ptr
	;; 
.copy:
	move.b	(a3)+,(a2)+
	subq.l	#1,d1
	beq.s	.copy

	;; Replenish buffer
	jsr	isb_fill
	ble.s	.exit

	;;
	tst.l	d2
	beq.s	.loop
	
	;; 
	move.l	a2,d0
	sub.l	a1,d0		; d0: count
	rts

;;; ----------------------------------------------------------------------
;;;
;;; isb_tell() - Get stream position
;;;
;;; < a0.l buffer
;;; > d0.l position
	
isb_tell:	;; ------------------------------------,
	pea	(a0)		;
	movea.l	isb_inp(a6),a0	;
	jsr	if_tell		;
	bmi.s	.done		;
	sub.l	isb_len(a6),d0	;
	;; ------------------------------------`
.done:
	movea.l	(a7)+,a0
	rts
	
	
;;; ----------------------------------------------------------------------
;;;
;;; isb_fill() - Fill buffer
;;;
;;; < a0.l buffer
;;; > d0.l count or error

isb_fill:	;; ------------------------------------,
	movem.l	a0-a2,-(a7)		;
	move.l	isb_max(a0),d0	; d0: count
	lea	isb_dat(a0),a1	; a1: data
	move.l	isb_inp(a0),a0	; a0: input
	move.l	if_read(a0),a2	; a2: (*read)()
	jsr	(a2)		;
	movem.l	(a7)+,a0-a2		;
	bmi.s	.error		;
	clr.l	isb_idx(a0)		;
	move.l	d0,isb_len(a0)	;
	;; ------------------------------------`
.error:
	rts
	
	
;;; ----------------------------------------------------------------------
;;;
;;; isb_rewind() - Rewind buffer
;;;
;;; < a0.l buffer
;;; < d0.l rewind amount
;;; > sr#N set if no can do

isb_rewind:	;; ------------------------------------,
	pea	(a1)		;
	move.l	d0,a1		; a1: amount
	move.l	isb_idx(a0),d0	; d0: isb_idx
	sub.l	a1,d0		; have enough ?
	bmi.s	.no_can_do		;
	add.l	isb_len(a0),a1	;
	move.l	a1,isb_len(a0)	;
	move.l	d0,isb_idx(a0)	; * isb_idx
	;; ------------------------------------`
.no_can_do:
	movea.l	(a7)+,a1
	rts


;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
