;;; @file    fifo.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-25
;;; @brief   fifo definitions
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>


	IfND	FIFO_I
FIFO_I:	SET	1

	;; fifo struct
	rsreset
fifo_RW:	rs.l	0        ; fifo_R/fifo_L agregate
fifo_R:	rs.w	1        ; read index bit #15 mark full fifo
fifo_W:	rs.w	1        ; write index
fifo_len:	rs.w	1        ; fifo length
	rs.w	1        ; reserved
fifo_buf:	rs.b	0        ; buffer start here

	;; exported functions
	xdef	fifo_size
	xdef	fifo_used
	xdef	fifo_free
	xdef	fifo_push
	xdef	fifo_pull

	EndC ; FIFO_I
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
