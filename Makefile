
.SUFFIXES:
.DEFAULT_GOAL := all



################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

# Directory constants
SRCDIR  = src
BINDIR  = bin
OBJDIR  = obj
DEPSDIR = deps

# Program constants
RGBASM  = rgbasm
RGBLINK = rgblink
RGBFIX  = rgbfix
MKDIR   = $(shell which mkdir)

ROMFile = $(BINDIR)/$(ROMName).$(ROMExt)

# Project-specific configuration
include Makefile.conf


# Argument constants
ASFLAGS += -E -h -i $(SRCDIR)/ -i $(SRCDIR)/constants/ -i $(SRCDIR)/macros/ -p $(FillValue)
LDFLAGS += -d -p $(FillValue)
FXFLAGS += -j -f lh -i $(GameID) -k $(NewLicensee) -l $(OldLicensee) -m $(MBCType) -n $(ROMVersion) -p $(FillValue) -r $(SRAMSize) -t $(GameTitle)

# The list of "root" ASM files that RGBASM will be invoked on
ASMFILES := $(wildcard $(SRCDIR)/*.asm)



################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################

# Define how to compress files (same recipe for any file)
%.pb16: %
	src/tools/pb16.py $< $@

# RGBGFX generates tilemaps with sequential tile IDs, which works fine for $8000 mode but not $8800 mode; `bit7ify.py` takes care to flip bit 7 so maps become $8800-compliant
%.bit7.tilemap: src/tools/bit7ify.py %.tilemap
	$^ $@


CLEANTARGETS := $(BINDIR) $(DEPSDIR) $(OBJDIR) dummy # The list of things that must be cleared; expanded by the resource Makefiles
INITTARGETS :=

# Include all resource Makefiles
# This must be done before we include `$(DEPSDIR)/all` otherwise `dummy` has no prereqs
include $(wildcard $(SRCDIR)/res/*/Makefile)



# `all` (Default target): build the ROM
all: $(ROMFile)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
	-rm -rf $(CLEANTARGETS)
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

# `dummy` is a dummy target to build the resource files necessary for RGBASM to not fail on compilation
# It's made an actual file to avoid an infinite compilation loop
# INITTARGETS is defined by the resource Makefiles
dummy: $(INITTARGETS)
	@echo "THIS FILE ENSURES THAT COMPILATION GOES RIGHT THE FIRST TIME, DO NOT DELETE" > $@

# `.d` files are generated as dependency lists of the "root" ASM files, to save a lot of hassle.
# > Obj files also depend on `dummy` to ensure all the binary files are present, so RGBASM doesn't choke on them not being present;
# > This would cause the first compilation to never finish, thus Make never knows to build the binary files, thus deadlocking everything.
# Compiling also generates dependency files!
# Also add all obj dependencies to the deps file too, so Make knows to remake it
# RGBDS is stupid, so dependency files cannot be generated if obj files aren't,
#  so if a dep file is missing but an obj is there, we need to delete the object and start over
$(DEPSDIR)/%.d: $(OBJDIR)/%.o ;

$(OBJDIR)/%.o: DEPFILE = $(DEPSDIR)/$*.d
$(OBJDIR)/%.o: $(SRCDIR)/%.asm dummy
	@$(MKDIR) -p $(DEPSDIR)
	@$(MKDIR) -p $(OBJDIR)
	set -e; \
	TMP_DEPFILE=$$(mktemp); \
	$(RGBASM) -M $$TMP_DEPFILE $(ASFLAGS) -o $@ $<; \
	sed 's,\($*\)\.o[ :]*,\1.o $(DEPFILE): ,g' < $$TMP_DEPFILE > $(DEPFILE); \
	for line in $$(cut -d ":" -f 2 $$TMP_DEPFILE); do if [ "$$line" != "$<" ]; then echo "$$line: ;" >> $(DEPFILE); fi; done; \
	rm $$TMP_DEPFILE

# Include (and potentially remake) all dependency files
# Remove duplicated recipes (`sort | uniq`), hence using yet another file grouping everything
# Also filter out lines already defined in the resource Makefiles because defining two rules for the same file causes Bad Things(tm) (`grep`)
SPACE :=
SPACE +=
# Yes this "space" hack is NEEDED. I don't like where I'm going anymore, either
$(DEPSDIR)/all: $(patsubst $(SRCDIR)/%.asm,$(DEPSDIR)/%.d,$(ASMFILES))
	cat $^ | sort | uniq | grep -vE "^($(subst .,\\.,$(subst $(SPACE),|,$(strip $(INITTARGETS))))): ;" > $@
ifneq ($(MAKECMDGOALS),clean)
include $(DEPSDIR)/all
endif


# How to make the ROM
$(ROMFile): $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))
	@$(MKDIR) -p $(BINDIR)

	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm

	set -e; \
	TMP_ROM=$$(mktemp); \
	$(RGBLINK) $(LDFLAGS) -o $$TMP_ROM -m $(@:.gb=.map) -n $(@:.gb=.sym) $^ $(OBJDIR)/build_date.o; \
	$(RGBFIX) $(FXFLAGS) $$TMP_ROM; \
	mv $$TMP_ROM $(ROMFile)
