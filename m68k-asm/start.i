;;; @file    start.i
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-26
;;; @brief   TOS/GEM program startup
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	IfND	START_I
START_I:	Set	1

	
	Include	"gemdos.i"

STARTUP:	Macro ; \1:main \2:USP
	;; ------------------------------------

	TEXT
	xdef	start

start:
	;; Basic GEMDOS setup
	move.l	4(a7),a0		; a0:= Basepage
	;; IfNB	\2
	lea	\2,a7		; Private user stack
	;; EndC
	move.l	$0c(a0),a1		; a1:= TEXT size
	adda.l	$14(a0),a1		; a1+= DATA size
	adda.l	$1c(a0),a1		; a1+= BSS size
	lea	$100(a1),a1		; a1+= Basepage size
				; a1 = Program size

	;; Free memory
	pea	(a0)
	MSHRINK	a0,a1
	move.l	(a7)+,a0		; a0:= basepage

	;; Parse command line
	lea	128(a0),a1		; a1:= CLI
	move.l	a7,d0		; d0:= argv top
	moveq	#127,d1
	and.b	(a1)+,d1		; d1:= CLI length
	move.l	a1,a2		; a2:= Parsed cli
	;;
	moveq	#32,d3		; d3:= < >
	lea	.STskip(pc),a3	; a3:= .STskip
	bra.s	.next

	;; ------------------------------------
	;;  Command line parsing to argv[]
	;; ------------------------------------
	
.parse:
	move.b	(a1)+,d7		; d7:= <CHR>
	jmp	(a3)		; state machine

	;; ------------------------------------
	;; Status Skip (in between arguments)
.STskip:
	cmp.b	d3,d7		; ? < >
	beq.s	.next		; still < > continue

	;; Start of a new argument
	move.l	a2,-(a7)

	cmp.b	#39,d7		; ? <'>
	beq.s	.quoting		;
	cmp.b	#34,d7		; ? <">
	bne.s	.setplain		;

	;; Enter quoting mode
.quoting:
	lea	.STquot(pc),a3	; a3:= .STquot (assume)
	move.b	d7,d3		; d3:= <'> or <">
	bra.s	.next
	
.setplain:
	lea	.STcopy(pc),a3	; a3:= .STcopy
	moveq	#32,d3		; d3:= < >
	bra.s	.store

	;; ------------------------------------
	;; Status Quot (copy up to delimiter)
.STquot:
	cmp.b	d3,d7
	bne.s	.store
	moveq	#32,d3		; d3:= < > argument delimiter
	lea	.STcopy(pc),a3
	bra.s	.next

	;; ------------------------------------
	;; Status Copy word
.STcopy:
	cmp.b	#39,d7		; ? <'>
	beq.s	.quoting		;
	cmp.b	#34,d7		; ? <">
	beq.s	.quoting		;

	;; reach delimiter
	cmp.b	d3,d7
	bne.s	.store

.argclose:
	lea	.STskip(pc),a3
	moveq	#0,d7		; d7:= nil

.maybestore:
	
	;; and loops
.store:
	move.b	d7,(a2)+
.next:
	dbf	d1,.parse
	clr.b	(a2)		; close that argument


	;; reverse arguments order
	move.l	a7,a2		; a2: argv
	move.l	a2,a3		; a3: argv-lo
	move.l	d0,a1		; a1: argv-hi
	sub.l	a7,d0		;
	lsr.l	#2,d0		; d0: argc
	beq.s	.reversed
.reverser:	
	move.l	(a3),d1
	move.l	-(a1),(a3)+
	move.l	d1,(a1)
	cmp.l	a3,a1
	bhi.s	.reverser
.reversed:
	

	;; Exec main()
	pea	(a0)		; push basepage
	pea	(a2)		; push argv
	move.l	d0,-(a7)		; push argc
	jsr	\1		; main(argc,argv,bp)
	lea	12(a7),a7		; stack adjust
	;; Exit with d0
	PTERM	d0

	;; ------------------------------------
	EndM
	
	EndC	; START_I

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
