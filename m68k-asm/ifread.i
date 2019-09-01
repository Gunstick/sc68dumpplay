;;; @file    ifread.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   Read interface
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>


	IfND	IFREAD_I
IFREAD_I:	SET	1


	;; ifread struct
	rsreset
if_open:	rs.l	1		; open()
if_close:	rs.l	1		; close()
if_read:	rs.l	1		; read()
if_tell:	rs.l	1		; tell()
if_SZ:	rs.w	0

	;; GEMDOS implementation
	rsreset
dos_if:	rs.b	if_SZ		; Interface
dos_path:	rs.l	1		; Pointer to path
dos_pos:	rs.l	1		; Position
dos_hdl:	rs.w	1		; GEMDOS file handle
dos_SZ:	rs.w	0

dos_Decl:	Macro ; \1:path
	;; ------------------------------------
	dc.l	dos_open		;
	dc.l	dos_close		;
	dc.l	dos_read		;
	dc.l	dos_tell		;
	dc.l	\1		; Path
	dc.l	0		; Pos
	dc.w	-1		; Hdl
	;; ------------------------------------
	EndM
	
	;; Exported symbols
	xdef	dos_open,dos_close,dos_read,dos_tell

	EndC ; IFREAD_I
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
