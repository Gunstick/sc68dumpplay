;;; @file    dosread.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-09-01
;;; @brief   GEMDOS reader interface
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	include	"ifread.i"
	include	"gemdos.i"

;;; ----------------------------------------------------------------------
;;;
;;; dos_open() - Get FIFO buffer size
;;;
;;; < a0.l dosif struct
;;; > d0.l handle
;;; > sr#N set on error

dos_open:
	clr.w	dos_hdl(a0)
	clr.l	dos_pos(a0)
	pea	(a0)
	move.l	dos_path(a0),a0
	FOPEN	(a0),#0
	move.l	(a7)+,a0
	move.w	d0,dos_hdl(a0)
	rts

;;; ----------------------------------------------------------------------
;;;
;;; dos_close() - Get FIFO used space
;;;
;;; < a0.l dosif struct
;;; > d0.l error
;;; > sr#N set on error

dos_close:
	move.w	dos_hdl(a0),d0
	bmi.s	.error
	clr.w	dos_hdl(a0)
	pea	(a0)
	FCLOSE	d0
	move.l	(a7)+,a0
	bls.s	.error
	add.l	d0,dos_pos(a0)
	tst.l	d0
.error:
	rts

;;; ----------------------------------------------------------------------
;;;
;;; dos_read() - Read bytes
;;;
;;; < a0.l dosif struct
;;; < a1.l buffer
;;; < d0.l count
;;; > d0.l count or error

dos_read:
	pea	(a0)
	FREAD	dos_hdl(a0),(a1),d0
	move.l	(a7)+,a0
	rts

;;; ----------------------------------------------------------------------
;;;
;;; dos_tell() - Get position
;;;
;;; < a0.l dosif struct
;;; > d0.l position or error

dos_tell:	moveq	#-1,d0
	tst.w	dos_hdl(a0)
	bmi.s	.error
	move.l	dos_pos(a0),d0
.error:
	rts
	
;;; ----------------------------------------------------------------------
;;;
;;; dos_init() - Setup Interface
;;;
;;; < a0.l dosif struct
;;; > a1.l path

dos_init:
	move.l	#dos_open,(a0)+
	move.l	#dos_close,(a0)+
	move.l	#dos_read,(a0)+
	move.l	#dos_tell,(a0)+
	move.l	a1,(a0)+		; path
	clr.l	(a0)+		; position
	move.w	#-1,(a0)+		; handle
	suba.w	#dos_SZ,a0
	rts

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
