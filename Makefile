#!/usr/bin/make -f
#
# ----------------------------------------------------------------------
#
# GNU/makefile for this project
#
# By Benjamin Gerard AKA Ben/OVR
#

srcdir := $(dir $(lastword $(MAKEFILE_LIST)))

.SUFFIXES:
.SUFFIXES: .d .s .i .o .tos .ttp .prg
.DEFAULT_GOAL := all

vpath %.i $(srcdir)m68k-asm
vpath %.s $(srcdir)m68k-asm

# ----------------------------------------------------------------------

VLINK = vlink
VLINK.tos = $(strip $(VLINK) -b ataritos $(TOSFLAGS) $(VL-S) -o)

VASM = vasmm68k_mot
VASM.o = $(strip $(VASM) $(VASM_ASM) -Felf -o)
VASM.d = $(strip $(VASM) $(VASM_DEP) -depend=make -o)
VASM.tos = $(strip $(VASM)  $(VASM_FLAGS) -monst $(TOSFLAGS) -Ftos -o)

VASM_ASM = -quiet $(DEFS) $(INCS) $(VASM_CPU) $(MAXERRORS) $(NOCASE) $(NOSYM)\
 $(PIC) $(VASM_MOT) $(VASM_CPU) $(VASM_OPT)

VASM_DEP = -quiet $(DEFS) $(INCS) -maxerrors=1 $(NOCASE) -w -no-opt 

VASM_MOT = $(ALIGN) $(DEVPAC)
VASM_CPU = -m68000
VASM_OPT = -no-opt

MAXERRORS = -maxerrors=0
# PIC = -pic
# NOSYM = -nosym
# NOCASE = -nocase
ALIGN = -align
DEVPAC = -devpac #GB: I'm using IfNB 

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
VASM_OPT = -opt-speed -showcrit
DEFS = -DNDEBUG=1
NOSYM = -nosym
VL-S = -s
endif

ifneq ($(srcdir),./)

endif

# ----------------------------------------------------------------------
#  Targets definitions
# ----------------------------------------------------------------------

targets :=
programs := 

dirname = $(and $1,$1$(and $(FLAV),-$(FLAV))/)
dir.o := $(call dirname,_build)
dir.d := $(call dirname,_build)
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

$(eval $(call target_tpl,ymplay,prg,ymplay ymdump gemdos aes_fsel))
$(eval $(call target_tpl,testcli,ttp,testcli))

objects := $(sort $(foreach n,$(programs),$(value $n_objs)))
depends := $(sort $(foreach n,$(programs),$(value $n_deps)))
targets := $(foreach n,$(programs),$(value $n_prg))

all: $(targets)

$(ymplay_prg): DEFS+=-DTOS=1
$(call objnames,ymplay): INCS = -I$(srcdir)
clean: ; rm -f $(targets) $(objects) $(depends)
.PHONY: all clean

# ----------------------------------------------------------------------
#  Implicit pattern rules
# ----------------------------------------------------------------------

$(dir.d)%.d: %.s
	@test -d $(@D) || mkdir -p $(@D)
	$(VASM.d) $(@:%.d=%.o) $< >$@ || rm -f -- $@

$(dir.o)%.o: %.s
	@test -d $(@D) || mkdir -p $(@D)
	$(VASM.o) $@ $<

$(call prgnames,%.tos %.ttp %.prg):
	@test -d $(@D) || mkdir -p $(@D)
	$(VLINK.tos) $@ $^

# ----------------------------------------------------------------------
#  Dependencies
# ----------------------------------------------------------------------

dep depend depends: $(depends)
.PHONY: dep depend depends

ifndef NODEPS
ifneq ($(MAKECMDGOALS),clean)
$(depends) $(objects): $(lastword $(MAKEFILE_LIST))
-include $(depends)
endif
endif
