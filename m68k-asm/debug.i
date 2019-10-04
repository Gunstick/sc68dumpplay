;;; @file   debug.i
;;; @date   2019-09-25
;;; @author Ben/OVR
;;; @brief  debug definitions
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	IfND	DEBUG_I
DEBUG_I:	set	1

;; macro for debuging and check stuff
;; i.e. to chack that d0 is #42 at this moment, insert
;; ASSERT eq,cmp.l,#42,d0
;; which generates this test:
;;   cmp.l #42,d0
;;   beq.s ok
;;   illegal
;; ok:
ASSERT:	Macro ; \1:cc \2:mnemonic \3:op1 \4:op2
	;; -------------------------------------
	IfD	DEBUG
	;; move	sr,-(a7)
	\2	\3,\4
	b\1.s	.assert\@
	illegal
.assert\@:
	;; move	(a7)+,ccr
	EndC	; DEBUG
	;; -------------------------------------
	EndM

	EndC	; DEBUG_I
	
;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
