#!/usr/bin/awk -f
# Optimizes an sc68 dump to only contain the minimal needed registers
# the mixer register is not yet optimized for each single bit.
# also shows statistics on which registers are used most in the song.

# why the hell did I still write this in awk? That way I will never learn python3!
# Gunstick 2019-08-17
BEGIN {
  split("0 0 0 0 0 0 0 0 0 0 0 0 0 0",count)
  split(". . . . . . . . . . . . . .",prev)
}
{#print $3
 output=$1 " " $2 " "
 rcnt=0
 split($3,cur,"-")
 for (i=1;i<=14;i++) {
   if(i==14){
     e=""
     if(cur[14]!="..") {
       prev[14]=""   # force write of envelope shape register
     }
   }else{
     e="-"
   }
   if(cur[i]==prev[i]) {
     output=output ".." e
   }else{ 
     output=output cur[i] e
     if (cur[i]!="..") {
       rcnt++
     }
     if(cur[i]!="..") {count[i]++}
   }
   if(cur[i]!="..") {
     prev[i]=cur[i]
   }
 }
 for (i=-1;i<7;i+=2) {
   #print i"=" cur[i] ":" cur[i+1]
   if( (cur[i]!="..") || (cur[i+1]!="..")) {
     f=(cur[i+1]==".."?""prev[i+1]:""cur[i+1]) (cur[i]==".."?""prev[i]:""cur[i])
     frequencies[f]++
   }
 }
 if(rcnt!=0) { print output}
 lines++
}
END{
  print lines " lines" > "/dev/stderr"
  print "Frequencies:" > "/dev/stderr"
  for (i=1;i<=14;i++) {
    printf "R" i-1 "=" count[i] "x " > "/dev/stderr"
    writes+=count[i]
  }
  print "" > "/dev/stderr"
  print "Total register writes:" writes > "/dev/stderr"
  print "Frequencies:" > "/dev/stderr"
  for (f in frequencies)
    print f " " strtonum("0x"f) " " int(2000000/16/(strtonum("0x"f)==0?1:f)) "Hz " frequencies[f] > "/dev/stderr"
}
