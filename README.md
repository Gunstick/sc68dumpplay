# sc68dumpplay
Plays an sc68 register dump on a real ST

Such a dump can be produced with
sc68 --ym-engine=dump --ym-clean-dump -qqq -o/dev/null  tune.sndh

You can optimize the register usage with optdump.awk
sc68 --ym-engine=dump --ym-clean-dump -qqq -o/dev/null Lap_27.sndh |
./optdump.awk | head -1000 > lap27.dmp

First version will just read the original ASCII and play it.
Think of it as a very bad YM player.
Probably too slow to play timer effects

Second version will use an optimized binary format and should be able
to play accurately enough.

Quick test directly from sndh
sc68 --ym-engine=dump --ym-clean-dump -qqq -o/dev/null CPU_Eater.sndh > CPU_Eater.dmp
./dumpcompress.py ympkst CPU_Eater.dmp > CPU_Eater.dmp.ascii
mv CPU_Eater.dmp.bin test.yms
make
hatari testyms.tos
