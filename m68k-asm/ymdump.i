;;; @file   ymdump.i
;;; @date   2019-08-24
;;; @author Ben/OVR
;;; @brief  ymdump definitions
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	IfND	YMDUMP_I
YMDUMP_I:	set	1

	Xdef	ymdmp_next,ymdmp_decode

	rsreset
ymdmp_clk:	rs.w	3
ymdmp_set:	rs.w	1
ymdmp_reg:	rs.b	14
ymdmp_SIZ:	rs.w	0

	EndC ; YMDUMP_I

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End: