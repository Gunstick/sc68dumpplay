;;; @file    xbios.i
;;; @date    2019-09-01
;;; @author  Ben/OVR
;;; @brief   Some Atari ST Xbios call macros
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	IfND	XBIOS_I
XBIOS_I:	SET	1


VSYNC:	Macro ;
	;; ------------------------------------
	move.w	#$25,-(a7)		; opcode
	trap	#14		; Xbios
	addq.w	#2,a7		; stack adjust
	;; ------------------------------------
	EndM

SUPEREXEC:	Macro ; \1:addr.l
	;; ------------------------------------
	move.l	\1,-(a7)		; routine address
	move.w	#$26,-(a7)		; opcode
	trap	#14		; Xbios
	addq.w	#6,a7		; stack adjust
	;; ------------------------------------
	EndM


	EndC ; XBIOS_I

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
