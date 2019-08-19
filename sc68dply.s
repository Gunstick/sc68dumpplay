; sc68 dump player

; open file (ok, maybe just include data, lol)

; read line

; play line

; wait (or irq?)

  include ulm-init.s

screen:
   move.w #$777,$ffff8240.w   ; unblack screen
   move.b #1,$ffff8260.w      ; mid rez
   jsr print
   dc.b "sc68 dump player",10,13,0
   lea sc68dump,a6   ; start of ascii dump
; 00000F 0000009C80 23-03-23-03-C8-00-1C-23-10-10-..-32-00-0A  
; 012345 7890123456 890123456789012345678901234567890123456789
; 000000 0001111111 111222222222233333333334444444444555555555
; vbl
playloop:
    lea (a6),a3
    ;lea 59(a3),a4    ; do not take crlf
    lea 7(a3),a4    ; do not take crlf
    ;jsr a3printa4
    ;jsr print        ; print only a cr to stay on same line
    ;dc.b 13,0
    ; let's see to play registers
    lea 7(a6),a3     ; start of ym clock
    bsr hexa3tod0
    move.l d0,d3
    sub.l prevclock,d3  ; difference
    move.l d0,prevclock 
    move.l d3,d0
    sub.l #50,d3   ; nop length of the decoder routine
    lsr.l #2,d3    ; some guesswork
waitclock:
    nop
    dbf d3,waitclock  ; just delay a little
    adda.l #18,a6    ; this points now to R0
    moveq #0,d3
regloop:      ; play all 13 values pointed to by a6
    cmp.b #'.',(a6)    ; no data, skip
    beq.s skipreg
    bsr a6hexchar2bind0
    move.b d3,$ffff8800.w   ; select register
    move.b d0,$ffff8802.w   ; write value
    lea 3(a6),a6
nextreg:
   cmpi.b  #57,$fffffc02.w
   beq     back
    addq.b #1,d3          ; next register number
    cmp.b #13,d3          ; we loop 14 times (0 to 13)
    ble.s regloop
    bra.s regloopend
skipreg:
    lea 3(a6),a6    ; we read a - so we skip this register
    bra.s nextreg
regloopend:
    ;bsr waitvbl    ; function offered by ulm-init.s 
    cmpa.l #enddump,a6    ; are we at end of dump
    ble playloop

no_key:
   cmpi.b  #57,$fffffc02.w
   beq     back

    cmpi.b  #1,$fffffc02.w
    bne.s   no_key

; exit demo
   jmp back
 

; some helper routines, not all used...   
a6hexchar2bind0:
  ; converts the hexadecimal 2 characters at a0 to d0 binary byte
    move.b (a6)+,d1  ; get up nibble
    bsr tobin        ; convert lower D0 to bin nibble
    move.b d1,d0     ; save value
    lsl #4,d0        ; move it to upper nibble
    move.b (a6)+,d1  ; get low nibble
    bsr tobin
    add.b d1,d0      ; add lower nibble to result
    lea -2(a6),a6    ; do not change a6
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
  movem.l d0-d3/a0-a3/a4,-(sp)
a3printa4next:
  cmpa.l    a3,a4
  beq.s a3printa4done
  clr.w     -(sp)  ; Offset 4 (make room for a word)
  move.b    (a3)+,1(sp)  ; Offset 4 (char to print)
  move.w    #2,-(sp)     ; Offset 2 device=2 console vt52
  move.w    #3,-(sp)     ; Offset 0 bconout=3
  trap      #13          ; Call BIOS
  addq.l    #6,sp        ; Correct stack
  bra.s a3printa4next
a3printa4done:
  movem.l (sp)+,d0-d3/a0-a3/a4
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
hexa3tod0:
 ;converts the hexadecimal chars a3 points to into d0.
 ;a3 points to the MSDigit. End of conversion if illegal character
 movem.l a3/d0/d1,-(sp)
 moveq #0,d0       ; clear working register d0
 moveq #0,d1
nexthexa3tod0:
 move.b (a3)+,d1   ; get a digit
 subi.b #"0",d1    ; is it greater than 0
 blo.s endhexa3tod0   ; if lower: bad char, i.e. space, stop here
 cmpi.b #9,d1      ; less than 9 ?
 ble.s _justdigit
 subi.b #7,d1      ; go to chars...
 cmpi.b #15,d1      ; less than 15?
 bhi.s endhexa3tod0 ; bad char... end
_justdigit
 lsl.l #4,d0
 add.l d1,d0
 bra.s nexthexa3tod0
endhexa3tod0:
 movem.l (sp)+,a3/d1/d2
 rts

bind0tohexa6:
  ; converts d0 to 8 chars stating at a6
  movem.l d0/d1/d2/a6,-(sp)
  moveq #7,d2
nextchar:
  rol.l #4,d0        ; rotate topmost nibble at bottom
  move.b d0,d1  ; low byte
  and.b #$0f,d1   ; mask nibble
  add.b #$30,d1   ; convert to number 
  cmp.b #$3a,d1   ; compare with >9
  blt isdigit
ischar:
  add.b #7,d1     ; make into char
isdigit:
  move.b d1,(a6)+
  dbf d2,nextchar
  movem.l (sp)+,d0/d1/d2/a6
  rts
; convert d0 to hax ascii and print to screen
printhexd0:
  movem.l d0-d3/a0-a3/a6,-(sp)
  lea hexstring,a6
  bsr bind0tohexa6
  move.l #hexstring,-(sp) ; address of text to print
  move.w #9,-(sp)        ; gemdos cconws 
  trap #1                ; call gemdos
  addq.l #6,sp           ; correct stack
  movem.l (sp)+,d0-d3/a0-a3/a6
  rts
hexstring:
  dc.b "        ",13,10,0
  even

   data
prevclock:
   dc.l 0
sc68dump:
  incbin "lap27.dmp"
  ;incbin "bla.dmp"
  ;incbin "breath.dmp"
  ;incbin "sidtor.dmp"
enddump:
  dc.b 0,0
