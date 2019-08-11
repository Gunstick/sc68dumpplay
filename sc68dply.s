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
    ; let's see to play registers
    adda.l #18,a6    ; this points now to R0
    moveq #0,d3
regloop:      ; play all 13 values pointed to by a6
    cmp.b #'.',(a6)    ; no data, skip
    beq.s skipreg
    bsr a6hexchar2bind0
    move.b d3,$ffff8800.w   ; select register
    move.b d0,$ffff8802.w   ; write value
    lea 1(a6),a6
nextreg:
    addq.b #1,d3          ; next register number
    cmp.b #13,d3          ; we loop 14 times (0 to 13)
    ble.s regloop
    bra.s regloopend
skipreg:
    lea 3(a6),a6    ; we read a - so we skip this register
    bra.s nextreg
regloopend:
 
    cmpa.l #enddump,a6    ; are we at end of dump
    ble.s playloop

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
   ; set PSG into defined state
psginit2:
        moveq   #15,d0
        lea     $ffff8800.w,a0
        lea     psginittab,a1
nextinit2:
        move.b  (a1)+,(a0)
        move.b  (a1)+,2(a0)
        dbf     d0,nextinit2
        rts


   rts
psginittab:dc.b 0,$ff,1,$ff,2,$ff,3,$ff,4,$ff,5,$ff,6,0
        dc.b 7,%11111011,8,0,9,0,10,0,11,5,12,100,13,2,$ff,0
        even
   
restore:                        ; go back into user mode
   move.w (sp)+,sr
   move.l oldstack,-(a7)
   move.w #32,-(a7)
   trap #1     
   addq.l #6,a7
   rts
a6hexchar2bind0:
  ; converts the hexadecimal 2 characters at a0 to d0 binary byte
    move.b (a6)+,d1
    bsr tobin        ; convert lower D0 to bin nibble
    move.b d1,d0     ; save value
    move.b (a6)+,d1
    bsr tobin
    lsl #4,d1
    add.b d1,d0
    rts 
tobin:
    cmp.b #'A',d1    ; check if A-F
    blt nochar
    sub.b #7,d1      ; move chars close to nums
nochar:
    sub.b #$30,d1    ; convert binary
    rts

    bra.s hexdone
nothex:
    sub.b #'0',d0    ; convert ascii '0'-'9' to binary
hexdone:
    blt.s novalue    ; unable to convert
    cmp.w #30*256,d0 ; if bigger than "9"x, substract for hex
    ble.s nothex_
    sub.w #'A'*256,d0  ; convert ascii 'A'x-'F'x to binary
    bra.s hexdone_
nothex_:
    sub.w #'0'*256,d0    ; convert ascii '0'-'9' to binary
hexdone_:
    blt.s novalue    ; unable to convert
    nop
novalue: 
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
