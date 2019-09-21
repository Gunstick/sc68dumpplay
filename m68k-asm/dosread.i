;;; @file    dosread.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   GEMDOS reader definition
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	IfND	DOSREAD_I
DOSREAD_I:	Set	1


	Include	"ifread.i"

	;; GEMDOS implementation
	rsreset
dos_if:	rs.b	if_SZ		; |interface
dos_path:	rs.l	1		; |pointer to path
dos_pos:	rs.l	1		; |position
dos_hdl:	rs.w	1		; |GEMDOS file handle
dos_SZ:	rs.w	0

dos_DS:	Macro ; \1:number
	ds.b	dos_SZ*(\1)
	EndM

	;; < a0=dos struct
	;; > d0.l return value
	;; > SR#N is set on error clear on success
	xref	dos_init	; <a1=path >error
	xref	dos_open	; >handle
	xref	dos_close	; >error
	xref	dos_read 	; <a1:buf <d0.l:count >d0.l:count
	xref	dos_tell	; >d0.l:pos

	EndC	; DOSREAD_I

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
