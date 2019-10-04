;;; @file	testyms.s
;;; @author	Gunstick/ULM & Ben/OVR
;;; @date	2019-09-27
;;; @brief	Program testing the decoder of the binary ym-stream format.
;;;
;;; This is free and unencumbered software released into the public domain.
;;; For more information, please refer to <http://unlicense.org>
;;;

	IfND	TCR
TCR:	Set	3 ; timer control register value: 1/3/5 -> 4/16/64
	EndC

	;; GB: This is the log2 (2^TDR) of TDR value to program the timer.
	;;     As I am now almost certain that there is no problem with the
	;;     zero read, there is pretty much no reason to use anything
	;;     but 8.
	IfND TDR
TDR:	Set	8 ; timer data register log2(TDR)
	EndC

TDR_MSK:	SET (1<<TDR)-1	           ; i.e. 8 => 01111111

	IfEQ	TCR & 1
	fail	"TCR must be odd"
	EndC

	IfLT	5-TCR
	fail	"TCR must be less or equal to 5"
	EndC

	Include	"debug.i"
	Include	"yms.i"
	Include	"xbios.i"
	Include	"start.i"

; future: asynchronous decompress and playing: set to 0
BUFFERPLAY:	SET 1

	STARTUP	main,(a7)
main:	SUPEREXEC	#superrout
	rts

tArout:	addq.l	#1,va_tacount ; this is called at 2400/600/150 hz
	;; eor.w	#$333,$ffff8240.w
	;; move.b	#%11011111,$fffffa0F.w	; release In-Service
	rte

superrout:
	move.w	sr,savesr		; d1: save SR
	move.w	#$2700,sr
	moveq	#15,d0
	and.b	d0,$fffffa19.w	; test timerA
	beq.s	.timeroff

	;; Exit if timer-A appears to be running
	move.w	savesr,sr		; sr: restored
	moveq	#1,d0		; error
	rts

.timeroff:
	clr.b	$fffffa19.w		; timera::TCR=0 (Stop)
	move.b	#(1<<TDR)&255,$fffffa1f.w ; timera::TDR=256
	move.l	$134.w,save134	; save Timer-A vector
	move.l	#tArout,$134.w	; install new Timer-A Vector
	move.l	$fffffa06.w,savea06	; save iena
	move.l	$fffffa12.w,savea12	; save imsk

	;; Stop all mfp irqs but timer-a
	moveq	#$20,d0
	swap	d0
	move.l	d0,$fffffa06.w
	move.l	d0,$fffffa12.w

	;bset	#5,$fffffa07.w	; enable timer-A interrupt
	;bset	#5,$fffffa13.w	; unmask timer-A interrupt
	move.w	#$2500,sr		; IPL=5
	bclr	#0,$484.w		; No clicks
	bclr	#3,$fffffa17.w	; AEI


init_dmp:	;; ------------------------------------

	lea	ymsdata,a1
	bsr	yms_header
	;; >d0= time unit in Hz
	;; >a1= start of stream
	move.l	a1,va_curpos

	;; Calculate MFP values from Hz
	;; MFP clock is 2457600 hz
	;; e.g.  153.600Hz / 256 = 600
	;; with prediv 4: 600/4=150Hz
	;; with prediv 16: 600/16=37.5Hz
	;; for 2.457.600Hz / 256 = 9600
	;; with prediv 4: 9600/4=2400Hz timer
	;; with prediv 16: 9600/16=600Hz timer

	lea	ymsdata(pc),a1
	move.l	a1,va_begline
	move.l	#eof,va_endpos

	clr.l	va_tacount
	clr.l	va_nexttdr
	clr.l	va_nextevt

	;; TimerA::TCR=1 (/4)  -> start 2400-hz( 614400 precision)
	;; TimerA::TCR=3 (/16) -> start 600-hz ( 153600 precision)
	;; TimerA::TCR=5 (/64) -> start 150-hz (  38400 precision)

	move.b	#TCR,$fffffa19.w	; start timer-A
	;; ------------------------------------

	;; init player
	lea	ymdump(pc),a0	; write dump here
	lea	(pc),a2		; read dump here
	IfEQ	BUFFERPLAY
	move.w	#1000,d5
	move.l	va_curpos,a1		; read yms here
fillit:	;; pre-decode frames
	bsr	yms_decode
	dbf	d5,fillit
	EndC

play_dmp:	;; ------------------------------------
	IfNE	BUFFERPLAY
	lea	ymdump(pc),a2	; read dump here
	EndC

	move.w	#$070,$ffff8240.w	;

	;; Get next data
	move.l	va_curpos,a1		; read yms here
	cmp.l	va_endpos,a1		; reach <EOS> ?
	bhs	over		; yes -> exit

	bsr	yms_decode

	;; a0= points after the $ffff tag
	IfNE	BUFFERPLAY
	lea	ymdump(pc),a0	; jump back
	EndC
	move.l	a1,va_curpos

	;; Compute delta time to next event (straight forward with yms)
	move.l	(a2)+,d0

	;; GB: fixed point alignment (don't ask please) )
SHL:	Set	8+3-TCR+8-TDR
	IfGT	SHL-8
	moveq	#SHL,d1
	lsl.l	d1,d0
	else
	lsl.l	#SHL,d0
	EndC

	;; GB: This depends on the Timer-A frequency which depends on
	;;     TCR and TDR values. This clock is a 48 bits value.
	;;     The 32 MSB (first longword) is the timer counter.
	;;     The next byte is the precision given by the TDR. If TDR
	;;     does not use the 8 bits, some additionnal shifts will be
	;;     neccessary when comparing with the running TDR.
	;;
	;;     YMS does not need to stay in the unit used by testdmp,
	;;     which is a consequence of having to convert YM cycles to
	;;     MFP cycles.

	;; Increment the 48-bits timestamp of the event (nextevt.l:nexttdr.w)
	lea	va_nextevt,a6	;
	move.l	(a6)+,d7		; d7= va_nextevt
	add.w	d0,(a6)		; *va_nexttdr
	move.b	(a6),d6		; *d6= CNT goal (va_nexttdr MSB)
	clr.w	d0		;
	swap	d0		; lsr.l #16,d0
	addx.l	d0,d7		; *d7= CNT goal
	move.l	d7,-(a6)		; *va_nextevt

	;; d6.b: TDR goal
	;; d7.l: tacount goal

	move.w	#$700,$ffff8240.w
	lea	$ffff8800.w,a6	; *a6= PSG
	lea	$fffffc02.w,a5	; *a5= keyboard acia
	lea	$fffffa1f.w,a4	; *a4= TimerA TDR register
	lea	va_tacount,a3	; *a3= TimerA counter
	moveq	#$39,d0		; *d0= <SPC> scan code

.test_key:
	ASSERT	eq,cmp.b,#$39,d0	; d0 MUST be $39
	ASSERT	eq,cmpa.w,#$fc02,a5	; a5 MUST be $fc02.w
	cmp.b	(a5),d0		; <SPC> pressed ?
	beq	over		; yes -> exit

	;; GB: Ugly loop to be sure TDR and Counter are in sync.
	;; The idea is that if a timer interrupt has occured the TDR
	;; has looped
.resync:
	ASSERT	eq,cmpa.l,#va_tacount,a3	; a3 MUST be va_tacount
	ASSERT	eq,cmpa.w,#$fa1f,a4	; a4 MUST be $fa1f.w
	;;
	move.l	(a3),d4		; d4= TimerA IRQ Counter value
	move.b	(a4),d1		; *d1= TDR
	move.l	(a3),d3		; *d3= TimerA IRQ Counter value (again)
	cmp.w	d4,d3		; has it changed ?
	beq.s	.okcounter		; if not, counter is consistent
	move.b	(a4),d1		; else re-read TDR
.okcounter:
	;;
	cmp.l	d3,d7		; reach ta_count ?
	beq.s	.himatch
	blo.s	.synced ; late, just go ahead trying to catch up
	bhi.s	.test_key		;
.himatch:
	neg.b	d1		; d1 = 0-d1
	;; GB: According to my test on a real 1040-STf it's not
	;; possible to catch a 0 on the 1 to 0 transition therefore
	;; it is always the timer reload value (->256).
	;;
	*beq.s	.resync		; GB: not sure what to do

	;; GB:
	;; beq.s	.resync		; GB: not sure what to do
	IfNE	255-TDR_MSK
	and.w	#TDR_MSK,d1		; d1= TDR_MSK-d1
	EndC
	cmp.b	d6,d1		; compare TDR to goal
	blo.s	.resync		; not yet there

.synced:	; we get here when IRQ counter + timer counter are at the correct value, or more
	move.w	#$777,$ffff8240.w


	;; Commit events to YM
	;;
	;; GB: This need to be a tower if possible. For that yms_decode()
	;;     must count the number of register to be updated rather
	;;     than using an end marker.
	;;
	;;     movep.w d1,0(a6)  -> 4 nops |
	;;     move.w (a2)+,d1   -> 2 nops | -> 6 nops
	;;
	;;     o Can the decoder generate longword values for less than that ?
	;;       Probably not.
	;;
	;;     move.l (a2)+,(a6) -> 5 nops
	;;
	;;     o We can you use shadow registers for the machines that support
	;;       it (not the Falcon).
	;;
	;;     movep.l d1,0(a6)  -> 6 nops |
	;;     move.l (a2)+,d1   -> 3 nops | -> 9 nops -> 4.5 nops per register


	ASSERT	eq,cmpa.w,#$8800,a6	; a6 MUST be $8800.w
	move.w	(a2)+,d1 ; expect at least 1 register update
	ASSERT	pl,cmp,#0,d1		; d1 MUST be >= 0
.nextreg:
	movep.w	d1,0(a6)
	move.w	(a2)+,d1 ; yms struct is just $0rvv $0rvv ...
	bpl.s	.nextreg		; end when $ffff

	IfNe BUFFERPLAY
	;lea 1(a2,d1.w),a2      ; a2+1+(-1)=a2	  this does
	;move.l (a2)+,a2        ; another way for jump back
	EndC

	bra	play_dmp

over:
	clr.b	$fffffa19.w		; Stop timer-A
	move.w	#$2700,sr
	move.l	savea06,$fffffa06.w
	move.l	savea12,$fffffa12.w
	bset	#3,$fffffa17.w	; SEI
	move.l	save134,$134.w	; restore timer-A vector
	move.w	#$777,$ffff8240.w	; restore background color
	lea	$ffff8800.w,a0	; mute YM2149
	move.l	#$08000000,(a0)	;
	move.l	#$09000000,(a0)	;
	move.l	#$0A000000,(a0)	;
	move.l	#$0700FF00,(a0)	;
	stop	#$2300
	moveq	#0,d0		; no error
	rts


	DATA

va_begline:	ds.l	1
va_endpos:	ds.l	1
va_curpos:	ds.l	1

va_tacount:	ds.l	1
va_nextevt:	ds.l	1		; | GB: keep together
va_nexttdr:	ds.w	1		; |

savea06:	ds.l	1
savea12:	ds.l	1
save134:	ds.l	1
savesr:	ds.w	1

ymdump:

	Rept	500
	ds.l	1	  ; delta of mfp ticks
	ds.w	16	  ; movep data terminated by $ffff
	EndR

	;; GB: Or altenatively much faster on a real ST 
	;; ds.b	500*(4+16*2)		; 500 x { delta.l, 16 x { Reg.b, Val.b } }


ymsdata:	incbin	"test.yms"
eof:
	even

;;; Local Variables:
;;; mode: asm
;;; indent-tabs-mode: t
;;; tab-width: 13
;;; comment-column: 52
;;; End:
