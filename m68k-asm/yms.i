;;; @file   yms.i
;;; @date   2019-09-28
;;; @author Gunstick & Ben/OVR
;;; @brief  yms definitions
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	IfND	YMS_I
YMS_I:	set	1

	xref	ymdmp_next
	xref	yms_decode
	; xref	ymdmp_dclock

	rsreset
ymdmp_clk:	rs.w	3
ymdmp_set:	rs.w	1
ymdmp_reg:	rs.b	14
ymdmp_SIZ:	rs.w	0

	EndC	; YMDUMP_I

ymdmp_DS:	Macro
	ds.b	ymdmp_SIZ
	EndM
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
