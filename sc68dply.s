; sc68 dump player

; open file (ok, maybe just include data, lol)

; read line

; play line

; wait (or irq?)

intin equ   8                   ; setup some constants
ptsin equ   12

start:
   jsr   initialize  

   jsr print
   dc.b "sc68 dump player",10,13,0
;   move.l #hello,-(sp)    ; address of text to print
;   move.w #9,-(sp)        ; gemdos cconws 
;   trap #1                ; call gemdos
;   addq.l #6,sp           ; correct stack

   lea sc68dump,a6   ; start of ascii dump
; 00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A  
; 012345 7890123456 890123456789012345678901234567890123456789
; 000000 0001111111 111222222222233333333334444444444555555555
; vbl
playloop:
    lea (a6),a3
    lea 59(a3),a4    ; do not take crlf
    jsr a3printa4
    jsr print        ; print only a cr to stay on same line
    dc.b 13,0
    adda.l #60,a6
    cmpa.l #enddump,a6

    blt.s playloop
 
;   move.l #sc68dump,-(sp) ; address of text to print
;   move.w #9,-(sp)        ; gemdos cconws 
;   trap #1                ; call gemdos
;   addq.l #6,sp           ; correct stack

   move.l #presskey,-(sp)    ; address of text to print
   move.w #9,-(sp)        ; gemdos cconws 
   trap #1                ; call gemdos
   addq.l #6,sp           ; correct stack

   move.w   #7,-(a7)
   trap  #1                     ;wait keypress
   addq.l   #2,a7 
   jsr   restore
   clr.l    -(a7)               ;call gemdos
   trap  #1
   
initialize:                     ; go into super user mode
   clr.l -(a7) 
   move.w #32,-(a7)  
   trap #1     
   addq.l #6,a7   
   move.l d0,oldstack
   rts
   
restore:                        ; go back into user mode
   move.l oldstack,-(a7)
   move.w #32,-(a7)
   trap #1     
   addq.l #6,a7
   rts
a3printa4:
  ; prints chars from a3 (included) to a4 (excluded)
  ; on return a3=a4
  cmpa.l    a3,a4
  beq.s a3printa4done
  clr.w     -(sp)  ; Offset 4 (make room for a word)
  move.b    (a3)+,1(sp)  ; Offset 4 (char to print)
  move.w    #2,-(sp)     ; Offset 2 device=2 console vt52
  move.w    #3,-(sp)     ; Offset 0 bconout=3
  trap      #13          ; Call BIOS
  addq.l    #6,sp        ; Correct stack
  bra.s a3printa4
a3printa4done:
  rts
; a dumb print routine which prints the inline string after the jsr call until \0
print:
 movem.l d0-d7/a0-a6,-(a7)
 move.l $3c(a7),a5    ; get ret adress = text adress
 move.l a5,-(a7)
 move.w #9,-(a7)      ; cconws
 trap #1              ; GEMDOS
 addq.l #6,a7
printloop:
 tst.b (a5)+
 bne.s printloop   ; if not 0 then get next
 move.l a5,$3c(a7) ; write end of string adress = ret adress
 movem.l (a7)+,d0-d7/a0-a6
 btst #0,3(a7)     ; test lsb of ret adress
 beq.s printstringok  ; 0 => even adress , OK
 addq.l #1,(a7)    ; set to next even adress
printstringok:
 rts
deza3tod0:
 ;converts the decimal chars into d0.
 ;a3 points to the MSDigit. End of conversion if illegal character
 movem.l a3/d1/d2,-(a7) ;save used registers
 moveq #0,d0       ; clear working register d0
 moveq #0,d1
nextdeztohex:
 move.b (a3)+,d1   ; get a digit
 subi.b #"0",d1    ; is it greater than 0
 blo.s enddeztohex
 cmpi.b #9,d1      ; less than 9 ?
 bhi.s enddeztohex
 move.l d0,d2
 add.l d0,d0
 add.l d0,d0
 add.l d2,d0
 add.l d0,d0
 add.l d1,d0         ;  then add
 bra.s nextdeztohex
enddeztohex:
 movem.l (a7)+,a3/d1/d2
 rts

oldstack dc.l 0

   data
hello:
  dc.b "Hello World",10,13,10,13,0
  even
presskey:
  dc.b 10,13,"Press key",0
  even
sc68dump:
  incbin "lap27.dmp"
enddump:
  dc.b 0,0
