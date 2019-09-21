;;; @file    ymplay.s
;;; @author  Benjamin Gerard AKA Ben/OVR
;;; @date    2019-08-24
;;; @brief   sc68 YM dumps player 
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>

	;; opt	O+,W+
	
BUFFERSZ:	Set	1024
	
	Include	"start.i"
	Include	"dosread.i"
	Include	"aes.i"

	STARTUP	main,ustack

main:
	CCONWS	#cls

	move.l	$4(a7),d0		; d0: argc
	move.l	$8(a7),a0		; a0: argv 
	;; move.l	$c(a7),a1		; a1: basepage

	subq	#1,d0
	bmi	filesel

	move.l	(a0),a1		; a1: path
	bra	fileini

filesel:	
	;; Init GEM/AES
	bsr	aes_init	      ; Setup GEM/AES
	lea	omask,a0	      ; "*.DMP"
	bsr	aes_mask	      ; Setup fileselector mask
	bsr	aes_fsel	      ; Call AES fileselector
	tst.l	d0	      ; Canceled ?
	beq	exit_error
	move.l	d0,a1		; a1: Path

	;; Open dump file (a1:path)
fileini:	lea	dos,a0		; a0: DOS struct
	move.l	a1,dos_path(a0)	; * dos_path
	bsr	dos_init		;
	bsr	dos_open		;

	;; move.l	a0,a1		; a1: Dos
	;; lea	isb,a0		; a0: isb
	;; move.l	#BUFFERSZ,d0		; d0: isb size
	;; bsr	isb_init		; isb_init()
	;; bsr	isb_open		; isb_open()

	bmi	exit_error

loop:	moveq	#60,d0
	lea	line,a1
	
	lea	dos,a0
	bsr	dos_read
	bmi.s	exit_close
	cmp.w	#60,d0
	bls	exit_close

	lea	-1(a1,d0.l),a2
	move.b	(a2),-(a7)
	pea	(a2)
	clr.b	(a2)
	CCONWS	a1
	move.l	(a7)+,a2
	move.b	(a7)+,(a2)

	CCONWS	#cr
	bra	loop
	
exit_close:
	;; lea	isb,a0		; a0: isb
	;; bsr	isb_close		;
	lea	dos,a0
	bsr	dos_close
	
exit_error:	moveq	#-1,d0
exit:	rts
	
;;; *******************************************************

;; 	;; Save A7 and SR for clean exit
;; 	lea	stack_data(pc),a0
;; 	move	sr,(a0)+
;; 	move.l	a7,(a0)+
;; 	move.l	d0,(a0)+

;; 	;; Set supervisor stack
;; 	lea	sstack(pc),a7

;; 	;; Save ST status
;; 	bsr	save_st
	

;; 	;; Restore ST status
;; 	bsr	rest_st
	
;; 	;; Back to user mode
;; 	lea	stack_data(pc),a0
;; 	move.w	(a0)+,sr
;; 	move.l	(a0)+,a7
;; 	rts

;; ;;; *******************************************************

;; save_st:
;; 	rts

	IFD	toto
	
;; rest_st:
	;; 	rts

	moveq	#0,d1		; d1: delta-time
	moveq	#0,d7		; d7: zero

	move.l	(a0)+,d0		; oplong
	bmi	.extended
	swap	d0		; d0: RRVV-TIME
	add.w	d0,d1
	addx.l	d7,d1		; [deltacode]
	beq	.now
	
	cmp.l	d2,d1		; active ?
	bhi	.s
.s:	

.extended:	
	neg.l	d0


.now:
	;; add.l	

	ENDC	
	
;;; TimeCode.w <= 0 -> extended time code 
;;;            else -> delta clock
;;;
;;; DCA98 76420
;;;
;;;
;;;
;;;
;;;
;;; 

;;; ------------------------------------------------
;;; ------------------------------------------------
;;; 
	even
	DATA
	
omask:	dc.b	"*.DMP",0		; Fileselect mask
cls:	dc.b	27,"E",27,"f",27,"w",0	; CLS and setup
cll:	dc.b	27,"L",0		; Clear line
crlf:	dc.b	13,10,0		; CR/LF
cr:	dc.b	13,0		; CR

;;; ------------------------------------------------
;;; ------------------------------------------------
;;; 
	even
	BSS

line:	ds.b	84
dos:	dos_DS	1
;; isb:	isb_DS	BUFFERSZ
	
	;; Our stacks
	even
	ds.l	64
ustack:	ds.l	1
	ds.l	511
sstack:	ds.l	1
	

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
