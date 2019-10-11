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
'''
for SNDH_FILE in examples/*.sndh
do
  DMP_FILE="${SNDH_FILE/.sndh/}".dmp
  echo "Working on $SNDH_FILE"
  sc68 --ym-engine=dump --ym-clean-dump -qqq -o/dev/null "$SNDH_FILE" > "$DMP_FILE"
  ./dumpcompress.py ympkst "$DMP_FILE"
done

# test one file:
cp examples/CPU_Eater.dmp.yms test.yms
make
hatari testyms.tos
'''
