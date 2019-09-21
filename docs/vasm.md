VASM command line
=================

General Assembler Options:
-------------------------

* `-chklabels`<br/>
    Warn when symbols matchs reserved keywords.
* `-D{name}[=expression]`<br/>
    Define a symbol.
* `-depend={type}`<br/>
    Print dependencies while assembling. *NO OUTPUT IS GENERATED*.
* `-dependall={type}`
* `-dwarf[=version]`
* `-esc`<br/>
    Enable C-style escape character sequences in strings.
* `-F{fmt}`<br/>
    Set ouput format.
* `-I{path}`<br/>
    Add include path.
* `-ignore-mult-inc`<br/>
    Include the same file path only once.
* `-L` {listfile}<br/>
    Generate listing file.
* `-Ll{lines}<br/>
    Set the number of lines per listing file page.
* `-Lnf`<br/>
    No form feed into generatied listing for new parges.
* `-Lns<br/>
    Do not include symbols in the listing file.
* `-maxerrors=n`<br/>
    Max number of error before abortion (0=infinite).
* `-maxmacrecurs=n`<br/>
    The maximum of number of recursions within a macro.
* `-nocase`<br/>
    Disables case-sensitivity for everything.
* `-noesc`<br/>
    No escape character sequences.
* `-noialign`<br/>
    Perform no automatic alignment for instructions.
* `-nosym`<br/>
    Strips all local symbols from the output file.
* `-nowarn=n`<br/>
    Disable warning message <n>.
* `-o {ofile}`<br/>
    Set output file (or make depend target).
* `-pic`<br/>
    Generates position independant code or fail.
* `-quiet`<br/>
    No copyright notice nor final statistics.
* `-unnamed-sections`<br/>
    Merges section with same attribut ignoring their names.
* `-unsshift`<br/>
    Shift-right operator (>>) is unsigned
* `-w`<br/>
    Hide all warning messages.
* `-wfail`<br/>
    Warnings generate errors.
* `-x`<br/>
    Show an error message, when referencing an undefined symbol.


 Mot syntax module:
 =================

* `-align`<br/>
    Enables natural alignment for data.
* `-allmp`<br/>
    Enable macro additional 35 instead of 9 (\a to \z).
* `-cnop=code`<br/>
    Sets a two-byte code used for alignment padding with CNOP.
* `-devpac`<br/>
    Devpac-compatibility mode.
* `-ldots`<br/>
    Allow dots (.) within all identifiers.
* `-localu`<br/>
    Local symbols are prefixed by '_' instead of '.'.
* `-phxass`<br/>
    PhxAss-compatibilty mode.
* `-spaces`<br/>
    Allow blanks in the operand field.
* `-warncomm`<br/>
    Warn about all lines, which have comments in the operand field,
    introduced by a blank character.


 ELF output module:
 =================

* `-keepempty`<br/>
    Do not delete empty sections without any symbol definition.

 a.out output module:
 ===================

* `-mid={machine-id}`<br/>
    Sets the MID field of the a.out header to the specified value.

 TOS output module:
 =================

* `-monst`<br/>
    Write Devpac "MonST"-compatible symbols.

* `-tos-flags={flags}`<br/>
    Sets the flags field in the TOS file header.


 m68k cpu module:
 ===============

 CPU selection:
 -------------

* `-mcfv2` `-mcfv3` `-mcfv4` `-mcfv4e`
* `-m68851` (MMU)
* `-m68881` `-m68882` `-no-fpu` (FPU)
* `-m68000` `-m68008` `-m68010` `-m68020` `-m68030` `-m68040` `-m68060` `-m68020up` `-m68080`
* `-mcpu32`
* `-mcf5{coldfire-type}` `-m5{coldfire-type}`

        ColdFire types :=
           5202, 5204, 5206, 520x, 5206e, 5207, 5208, 5210a, 5211a,
           5212, 5213, 5214, 5216, 5224, 5225, 5232, 5233, 5234, 5235,
           523x, 5249, 5250, 5253, 5270, 5271, 5272, 5274, 5275, 5280,
           5281, 528x, 52221, 52553, 52230, 52231, 52232, 52233, 52234,
           52235, 52252, 52254, 52255, 52256, 52258, 52259, 52274,
           52277, 5307, 5327, 5328, 5329, 532x, 5372, 5373, 537x, 53011,
           53012, 53013, 53014, 53015, 53016, 53017, 5301x, 5407, 5470,
           5471, 5472, 5473, 5474, 5475, 547x, 5480, 5481, 5482, 5483,
           5484, 5485, 548x, 54450, 54451, 54452, 54453, 5445x


 Optimization:
 ------------

* `-no-opt`<br/>
    Disable all optimizations.
* `-opt-allbra`<br/>
    Optimize even branch with a valid size specified
* `-opt-brajmp`<br/>
    BRA/JMP_pc into jmp_abs accross sections
* `-opt-clr`<br/>
    MOVE #0,<ea> into CLR <ea> for the MC68000
* `-opt-fconst`<br/>
    Floating point constants are loaded with the lowest precision possible.
* `-opt-jbra`<br/>
    JMP/JSR into BRA.L/BSR.l (>=020)
* `-opt-lsl`<br/>
    LSL #1 into ADD.
* `-opt-movem`<br/>
    MOVEM <ea>,Rn into MOVE <ea>,Rn.
* `-opt-mul`<br/>
    Immediate multplication factors into instructions.
* `-opt-div`<br/>
    Immediate multplication factors into instructions.
* `-opt-pea
    MOVE.L #x,-(SP) into PEA x.
* `-opt-speed
    Optimize for speed, even if this would increase code size.
* `-opt-st
    Enables optimization from MOVE.B #-1,<ea> into ST <ea>.
* `-sc
    Abasolute/External JMP and JSR into into 16-bit PC-relative jumps.
* `-sd
    References to absolute symbols in a small data section (named
    "__MERGED") are optimized into a base-relative addressing mode
    using the current base register set by an active NEAR
    directive. This option is automatically enabled in ‘-phxass’
    mode.
* `-showcrit
    Print all critical optimizations which have side effects
* `-showopt
    Print all optimizations and translations vasm is doing (same as opt ow+). 


 Other options:
 -------------

* `-conv-brackets`<br/>
    Brackets '[]' into parentheses '()' as long as the CPU is 68000 or 68010.
* `-devpac`<br/>
    All options are initially set to be Devpac compatible.
* `-elfregs`<br/>
    Register names are preceded by a ’%’.
* `-gas`<br/>
    Enable additional GNU-as compatibility mnemonics and syntax.
* `-guess-ext`<br/>
    Accept illegal size extensions for an instruction.
* `-kick1hunks
    Prevents optimization of JMP/JSR to 32-bit PC-relative (BRA/BSR).
* `-phxass`<br/>
    PhxAss-compatibilty mode.
* `-rangewarnings`<br/>
    Values which are out of range usually produce only awarning.
* `-sdreg=<n>`<br/>
    Set the small data base register to An. <n> is valid between 2 and 6.
* `-sgs`<br/>
    Additionally allow immediate operands to be prefixed by & instead
    of just by. This syntax was used by the SGS assembler.
* `-regsymredef`<br/>
    Allow redefining register symbols with EQUR.
