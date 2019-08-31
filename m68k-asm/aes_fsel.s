;;; @file    aes_fsel.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2018-04-09
;;; @brief   AES/GEM file selector
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

;;; ----------------------------------------------------------------------
	SECTION	text
;;; ----------------------------------------------------------------------

	xdef	aes_init
	xdef	aes_fsel		; d0> selected file path or 0.l
	xdef	aes_mask		; a0< filename
	xdef	aes_alert		; d0< def-button a0< text d0>button

;;; ----------------------------------------------------------------------
aes_init:
	movem.l	d0-a6,-(a7)
	lea	vars(pc),a6

	;; Setup AES Parameter Block
	lea	aespb(a6),a5

	lea	aescb(a6),a4
	move.l	a4,(a5)+		; * aespb_ctlblk

	lea	globl(a6),a4
	move.l	a4,(a5)+		; * aespb_global

	lea	intinp(a6),a4
	move.l	a4,(a5)+		; * aespb_intinp

	lea	intout(a6),a4
	move.l	a4,(a5)+		; * aespb_intout

	lea	adrinp(a6),a4
	move.l	a4,(a5)+		; * aespb_adrinp

	lea	adrout(a6),a4
	move.l	a4,(a5)+		; * aespb_adrout

AESctl:	Macro
	;; ------------------------------------
	lea	aes\1(pc),a4		;
	lea	aescb(a6),a5		;
	move.w	(a4)+,(a5)+		;
	move.l	(a4)+,(a5)+		;
	move.l	(a4)+,(a5)+		;
	bsr	aes		;
	;; ------------------------------------
	EndM

	;; AES 10: appl_init()
	AESctl	10
	move.w	intout(a6),appid(a6)

	movem.l	(a7)+,d0-a6
	rts

	;; Run AES command
aes:	lea	aespb(a6),a5
	move.l	a5,d1
	move.w	#$c8,d0		; #200 (AES)
	trap	#2
	rts

;;; ----------------------------------------------------------------------

aes_alert:
	movem.l	d1-a6,-(sp)

	lea	vars(pc),a6
	move.w	d0,intinp+0(a6)
	move.l	a0,adrinp+0(a6)
	AESctl	52
	move.w	intout+0(a6),d0
	ext.l	d0

	movem.l	(sp)+,d1-a6
	rts

;;; ----------------------------------------------------------------------


strcat:	tst.b	(a1)+
	bne.s	strcat
	subq.w	#1,a1

strcpy:	move.b	(a0)+,(a1)+
	bne.s	strcpy
	subq.w	#1,a1
	rts

;;; ----------------------------------------------------------------------

aes_mask:
	movem.l	d0/a0-a1,-(sp)
	;;
	moveq	#15,d0
	lea	mask+1(pc),a1
.cpy:	move.b	(a0)+,(a1)+
	dbeq	d0,.cpy
	clr.b	-(a1)
	;;
	movem.l	(sp)+,d0/a0-a1
	rts

;;; ----------------------------------------------------------------------

aes_fsel:
	movem.l	d1-a6,-(sp)
	lea	vars(pc),a6

	move.w	#$19,-(sp)		; Dgetdrv()
	trap	#1
	addq.w	#2,sp
	add.b	#"A",d0
	lea	fs_iinpath(a6),a1
	move.b	d0,(a1)+
	move.b	#":",(a1)+

	clr.w	-(sp)		; current driver
	pea	(a1)		; path buffer
	move.w	#$47,-(sp)		; Dgetpath(buf.l,drive)
	trap	#1
	addq.w	#8,sp

	lea	mask(pc),a0
	bsr	strcat

	;; AES 90: Fsel_Input
	lea	fs_iinpath(a6),a5
	move.l	a5,adrinp+0(a6)
	lea	fs_insel(a6),a5
	clr.b	(a5)
	move.l	a5,adrinp+4(a6)
	AESctl	90

	moveq.l	#0,d0
	tst.w	intout+0(a6)
	beq.s	.canceled
	tst.w	intout+2(a6)
	beq.s	.canceled

	;; Append filename to path
	lea	fs_insel(a6),a0
	lea	fs_iinpath(a6),a2
	move.l	a2,d0
	move.l	a2,a1
	moveq	#92,d1		; Backslash
.scan:
	move.b	(a2)+,d2
	beq.s	.done
	cmp.b	d1,d2
	bne.s	.scan
	move.l	a2,a1
	bra.s	.scan
.done:
	bsr	strcpy

.canceled:
	movem.l	(sp)+,d1-a6
	rts

;;; ----------------------------------------------------------------------
	DATA

aes10:	dc.w	10,0,1,0,0	; app_init() -> appid
aes52:	dc.w	52,1,1,1,0	; form_alert (button,text) -> button index
aes90:	dc.w	90,0,2,2,0	; fsel_input(inpath,inselect,&button)


mask:		dc.b "\*.*"
		ds.b 12

;;; ----------------------------------------------------------------------
	BSS

		rsreset
appid:		rs.w 1

aespb:		rs.w 0
aespb_ctlblk:	rs.l 1
aespb_global:	rs.l 1
aespb_intinp:	rs.l 1
aespb_intout:	rs.l 1
aespb_adrinp:	rs.l 1
aespb_adrout:	rs.l 1

aescb:		rs.w 0
aescb_opcode:	rs.w 1
aescb_intinp:	rs.w 1
aescb_intout:	rs.w 1
aescb_adrinp:	rs.w 1
aescb_adrout:	rs.w 1

globl:		rs.w 0
globl_aesver:	rs.w 1
globl_runlimit:	rs.w 1
globl_uidnbapp:	rs.w 1
globl_appdata:	rs.l 1
globl_rsrcptr:	rs.l 1		; set by rsrc_load()
globl_rsvptr:	rs.l 1
globl_rsvlen:	rs.w 1
globl_bitplan:	rs.w 1
globl_reserved:	rs.l 1
globl_cmaxh:		rs.w 1
globl_cminh:		rs.w 1

intinp:		rs.w 16
intout:		rs.w 10
adrinp:		rs.l 8
adrout:		rs.l 2

fs_iinpath:		rs.b 256
fs_insel:		rs.b 16

varsize:		rs.b 0

vars:		ds.w (varsize+1)/2
		even

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
