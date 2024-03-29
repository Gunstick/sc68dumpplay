;;; @file    ifread.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   Read interface
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>


	IfND	IFREAD_I
IFREAD_I:	Set	1

	;; ifread struct
	rsreset
if_open:	rs.l	1		; |open()
if_close:	rs.l	1		; |close()
if_read:	rs.l	1		; |read()
if_tell:	rs.l	1		; |tell()
if_SZ:	rs.w	0

	
	EndC	; IFREAD_I
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
