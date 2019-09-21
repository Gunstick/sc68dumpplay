;;; @file    gemdos.i
;;; @date    2019-08-24
;;; @author  Ben/OVR
;;; @brief   Some Atari ST Gemdos call macros
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	IfND	GEMDOS_I
GEMDOS_I:	Set	1


CRAWCIN:	Macro ;
	;; ------------------------------------
	move.w	#7,-(a7)		; <Crawcin>
	trap	#1		; Gemdos
	addq.w	#2,a7		; stack adjust
	;; ------------------------------------
	EndM
	
CCONWS:	Macro ; \1:text.l
	;; ------------------------------------
	move.l	\1,-(a7)		; text.l
	move.w	#9,-(a7)		; <Cconws>
	trap	#1		; Gemdos
	addq.w	#6,a7		; stack adjust
	tst.l	d0		; > tos error code
	;; ------------------------------------
	EndM
	
PTERM0:	Macro ;
	;; ------------------------------------
	clr.w	-(a7)		; <Pterm0>
	trap	#1		; Gemdos
	illegal			; Safety net
	;; ------------------------------------
	EndM

PTERM:	Macro ; \1:exitcode.w
	;; ------------------------------------
	move.w	\1,-(a7)		; exitcode.w
	move.w	#$4c,-(a7)		; <Pterm>
	trap	#1		; Gemdos
	illegal			; Safety net
	;; ------------------------------------
	EndM

PTERMRES:	Macro ; \1:keep.w \2:code.w
	;; ------------------------------------
	move.w	\2,-(a7)		; return-code.w
	move.l	\1,,-(a7)		; keep-count.l
	move.w	#49,-(a7)		; <PtermRes>
	trap	#1		; Gemdos
	illegal			; Safety net
	;; ------------------------------------
	EndM
	
FCLOSE:	Macro ; \1:hdl.w
	;; ------------------------------------
	move.w	\1,-(a7)		; handle
	move.w	#62,-(a7)		; opcode
	trap	#1		;
	addq.w	#4,a7		;
	tst.l	d0		; > tos error code
	;; ------------------------------------
	EndM

FOPEN:	Macro ; \1:path.l \2:mode.w
	;; ------------------------------------
	move.w	\2,-(a7)		; mode
	move.l	\1,-(a7)		; path
	move.w	#61,-(a7)		; opcode
	trap	#1		;
	addq.w	#8,a7		;
	tst.l	d0		; > handle
	;; ------------------------------------
	EndM

FREAD:	Macro ; \1:hdl.w \2:buffer.l \3:count.l
	;; ------------------------------------
	move.l	\2,-(a7)		; buffer
	move.l	\3,-(a7)		; count
	move.w	\1,-(a7)		; handle
	move.w	#63,-(a7)		; opcode
	trap	#1		;
	lea	12(a7),a7		;
	tst.l	d0		; count
	;; ------------------------------------
	EndM

MALLOC:	Macro ; \1:count.l (-1=get largest block size)
	;; ------------------------------------
	move.l	\1,-(a7)		; count.l
	move.w	#$48,-(a7)		; opcode
	trap	#1		;
	addq.w	#4,a7		;
	tst.l	d0		; > Address (0 on error)
	;; ------------------------------------
	EndM

MFREE:	Macro ; \1:addr.l
	;; ------------------------------------
	move.l	\1,-(a7)		; address.l
	move.w	#$49,-(a7)		; <Mfree>
	trap	#1		; Gemdos
	addq.w	#4,a7		; stack adjust
	tst.l	d0		; > tos error code
	;; ------------------------------------
EndM

MSHRINK:	Macro ; \1:addr.l \2:count.l
	;; ------------------------------------
	move.l	\2,-(a7)		; count.l
	move.l	\1,-(a7)		; addr.l
	clr.w	-(a7)		; dummy.w (must be 0)
	move.w	#$4a,-(a7)		; <Mshrink>
	trap	#1		; Gemdos
	lea	12(a7),a7		; stack adjust
	tst.l	d0		; > tos error code
	;; ------------------------------------
	EndM


	EndC	; GEMDOS_I

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
