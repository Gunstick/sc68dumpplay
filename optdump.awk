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
 printf $1 " " $2 " "
 split($3,cur,"-")
 for (i=1;i<=14;i++) {
   if(i==14){
     e=""
     if(cur[14]!="..") {
       prev[14]=""   # force write of envelope shape register
     }
   }else{
     e=" "
   }
   if(cur[i]==prev[i]) {
     printf(".." e)}
   else{ 
     printf(cur[i] e)
     if(cur[i]!="..") {count[i]++}
   }
   if(cur[i]!="..") {
     prev[i]=cur[i]
   }
 }
 print ""
 lines++
}
END{
  print lines " lines"
  print "Frequencies:"
  for (i=1;i<=14;i++) {
    printf "R" i-1 "=" count[i] "x " 
    writes+=count[i]
  }
  print ""
  print "Total register writes:" writes
}
