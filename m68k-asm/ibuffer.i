;;; @file    ibuffer.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-02
;;; @brief   Input Stream Buffer
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>


	IfND	IBUFFER_I
IBUFFER_I:	Set	1


	rsreset
isb_inp:	rs.l	1		; input interface
isb_idx:	rs.l	1		; current position
isb_len:	rs.l	1		; remaining data
isb_max:	rs.l	1		; allocated size
isb_dat:	rs.b	0		; data starts here
isb_SZ:	rs.b	0		; srtuct size


isb_DS:	Macro ; \1:size
	;; ------------------------------------
	even			;
	ds.b	isb_SZ+(\1)		;
	even			;
	;; ------------------------------------
	EndM
	
	;; Imported symbols
	xref	isb_init
	xref	isb_open
	xref	isb_close
	xref	isb_read
	xref	isb_tell
	xref	isb_rewind

	EndC	; IBUFFER_I
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
