#!/usr/bin/make -f
#
# ----------------------------------------------------------------------
#
# GNU/makefile for this project
#
# By Benjamin Gerard AKA Ben/OVR
#

MAKEFILE := $(lastword $(MAKEFILE_LIST))
srcdir := $(dir $(MAKEFILE))

.DELETE_ON_ERROR:
.SUFFIXES:
.SUFFIXES: .d .s .i .o .tos .ttp .prg
.DEFAULT_GOAL := all

vpath %.s $(srcdir)m68k-asm

# ----------------------------------------------------------------------

VLINK = vlink
VLINK.tos = $(strip $(VLINK) -b ataritos $(TOSFLAGS) $(VL-S) -o)

VASM = vasmm68k_mot
VASM.o = $(strip $(VASM) $(VASM_ASM) -Fvobj -o)
VASM.d = $(strip $(VASM) $(VASM_DEP) -depend=make -o)
VASM.tos = $(strip $(VASM) $(VASM_ASM) -monst $(TOSFLAGS) -Ftos -o)

VASM_ASM = -quiet $(DEFS) -I$(srcdir) $(or $(INCS),-I$(srcdir)) $(VASM_CPU) -x $(MAXERRORS) $(NOCASE)\
 $(NOSYM) $(PIC) $(VASM_MOT) $(VASM_CPU) $(VASM_OPT)
VASM_DEP = $(VASM_ASM)
VASM_MOT = $(ALIGN) $(DEVPAC)
VASM_CPU = -m68000
VASM_OPT = -showopt

MAXERRORS = -maxerrors=0
# PIC = -pic
# NOSYM = -nosym
# NOCASE = -nocase
ALIGN = -align
DEVPAC = -devpac

FLAV :=
# D=1 for debug build
ifeq ($(D),1)
FLAV := d
VASM_OPT = -no-opt
DEFS = -DDEBUG=1		# Define DEBUG=1
endif

# R=1 for release build
ifeq ($(R),1)
FLAV := r$(FLAV)
VASM_OPT = -opt-speed -showopt #-showcrit
DEFS = -DNDEBUG=1
NOSYM = -nosym
VL-S = -s
endif

# ----------------------------------------------------------------------
#  Targets definitions
# ----------------------------------------------------------------------

targets :=
programs := 

dirname = $(and $1,$1$(and $(FLAV),-$(FLAV))/)
dir.o := $(call dirname,_build/o)
dir.d := $(call dirname,_build/d)
dir.tos := $(call dirname,)

objnames = $(strip $(1:%=$(dir.o)%.o))
depnames = $(strip $(1:%=$(dir.d)%.d))
prgnames = $(strip $(1:%=$(dir.tos)%))

define target_tpl =
$1_nude := $3
$1_objs := $$(call objnames,$$($1_nude))
$1_deps := $$(call depnames,$$($1_nude))
$1_prg  := $$(call prgnames,$1.$2)
programs += $1
$$($1_prg): $$($1_objs)
endef

ymplay_nude = ymplay ymdump gemdos aes dosread ibuffer
$(eval $(call target_tpl,ymplay,prg,$(ymplay_nude)))
$(eval $(call target_tpl,testcli,ttp,testcli))
$(eval $(call target_tpl,testdmp,tos,testdmp ymdump))
$(eval $(call target_tpl,testyms,tos,testyms yms))

objects := $(sort $(foreach n,$(programs),$(value $n_objs)))
depends := $(sort $(foreach n,$(programs),$(value $n_deps)))
targets := $(foreach n,$(programs),$(value $n_prg))

all: $(targets)

# $(testdmp_prg): INCS = -I$(srcdir)
# $(testyms_prg): INCS = -I$(srcdir)
$(call objnames,testyms): $(srcdir)test.yms

# $(call depnames,testdmp): INCS = -I$(srcdir)
# $(call depnames,testyms): INCS = -I$(srcdir)

clean: ; rm -f -- $(wildcard $(targets) $(objects) $(depends))
clean-dir: ; rm -rf -- $(wildcard $(sort $(dir.d) $(dir.o) $(dir.tos)))
clean-all: clean-dir clean
.PHONY: all clean clean-dir clean-all

# ----------------------------------------------------------------------
#  Implicit pattern rules
# ----------------------------------------------------------------------

dir.all = $(sort $(dir.d) $(dir.o) $(dir.tos))

$(dir.all): ; mkdir -p -- "$@"

$(call objnames,%): %.s $(call depnames,%) $(MAKEFILE_LIST) | $(dir.all)
	$(VASM.o) $@ -depend=make -depfile $(call depnames,$*) $<

$(call prgnames,%.tos %.ttp %.prg): | $(dir.tos)
	$(VLINK.tos) $@ $^

%.yms: %.dmp
	$(srcdir)dumpcompress.py ympkst $< >/dev/null
	mv -v -- $<.bin $@

# ----------------------------------------------------------------------
#  Dependencies
# ----------------------------------------------------------------------

$(depends):
include $(wildcard $(depends))
