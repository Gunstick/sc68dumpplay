;;; @file   gemdos.s
;;; @date   2019-08-24
;;; @author Ben/OVR
;;; @brief  Some Atari ST Gemdos functions
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
	
	include	"gemdos.i"
	
;;; Fopen(fname.l,mode.w) => Handle or TOS error
;;; 
;;; Inp:
;;;  a0.l path
;;;  d0.w mode (0:R 1:W 2:RW)
;;;
;;; Out:
;;;  d0.w handle
;;; 
Fopen:	FOPEN	a0,d0
	rts

;;; Fclose(hdl.w) => TOS error
;;; 
;;; Inp:
;;;  d0.w handle
;;; 
;;; Out:
;;;  d0.l tos error (0=success)
;;;  N set on error
;;;  z set on success
;;; 
Fclose:	FCLOSE	d0
	rts

;;; Fread(hdl.w,buffer.l,count.l)
;;;
;;; Inp:
;;;  d0.w handle
;;;  a0.l buffer
;;;  d1.l count
;;;
;;; Out:
;;;  d0.l count or TOS error
;;;  N set on error
;;; 
Fread:	FREAD	d0,a0,d1
	rts

;;; Malloc(count.l)
;;;
;;; Inp:
;;;  d0.l count
;;;
;;; Out:
;;;  d0.l address or 0 on error
;;; 
Malloc:	MALLOC	d0
	rts

;;; Mfree(address.l)
;;;
;;; Inp:
;;;  d0.l address
;;;
;;; Out:
;;;  d0.l tos error (0=success)
;;;  N set on error
;;;  z set on success
;;; 
Mfree:	MFREE	d0
	rts

;;; Mshrink(addr.l,count.l)
;;;
;;; Inp:
;;;  a0.l address
;;;  d0.l count (new size)
;;;
;;; Out:
;;;  d0.l address or 0 on error
;;; 
Mshrink:	MSHRINK	a0,d0
	rts

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
