# sc68dumpplay
Plays an sc68 register dump on a real ST

Such a dump can be produced with
sc68 --ym-engine=dump --ym-clean-dump -qqq -o/dev/null  tune.sndh


Fist version will just read the original ASCII and play it.
Think of it as a very bad YM player.
Probably too slow to play timer effects

Second version will use an optimized binary format and should be able
to play accurately enough.


