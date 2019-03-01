
.SUFFIXES:
.DEFAULTTARGET: all


include Makefile.conf


# Directory constants
SRCDIR  = src
BINDIR  = bin
OBJDIR  = obj
DEPSDIR = deps

ROMFILE = $(BINDIR)/$(ROMName).$(ROMExt)

# Program constants
RGBASM  = rgbasm
RGBLINK = rgblink
RGBFIX  = rgbfix
MKDIR   = $(shell which mkdir)

# Argument constants
ASFLAGS += -E -h -i $(SRCDIR)/ -i $(SRCDIR)/constants/ -i $(SRCDIR)/macros/ -p $(FillValue)
LDFLAGS += -p $(FillValue)
FXFLAGS += -jv -i $(GameID) -k $(NewLicensee) -l $(OldLicensee) -m $(MBCType) -n $(ROMVersion) -p $(FillValue) -r $(SRAMSize) -t $(GameTitle)

# The list of "root" ASM files that RGBASM will be invoked on
ASMFILES := $(wildcard $(SRCDIR)/*.asm)



# `all` (Default target): build the ROM
.PHONY: all
all: $(ROMFILE)

# `clean`: Clean temp and bin files
.PHONY: clean
CLEANTARGETS := $(BINDIR) $(DEPSDIR) $(OBJDIR) $(SRCDIR)/res/build.date dummy # The list of things that must be cleared; expanded by the resource Makefiles
clean:
	-rm -rf $(CLEANTARGETS)

# `rebuild`: Build everything from scratch
.PHONY: rebuild
rebuild:
	$(MAKE) clean
	$(MAKE) all


# Define how to compress files (same recipe for any file)
%.pb16: %
	src/tools/pb16.py $< $@

# Include all resource Makefiles
include $(wildcard $(SRCDIR)/res/*/Makefile)


# `dummy` is a dummy target to build the resource files necessary for RGBASM to not fail on compilation
# It's made an actual file to avoid an infinite compilation loop
# INITTARGETS is defined by the resource Makefiles
dummy: $(INITTARGETS)
	@echo "THIS FILE ENSURES THAT COMPILATION GOES RIGHT THE FIRST TIME, DO NOT DELETE" > $@

# `.d` files are generated as dependency lists of the "root" ASM files, to save a lot of hassle.
# > Deps files also depend on `dummy` to ensure all the binary files are present, so RGBASM doesn't choke on them not being present;
# > This would cause the first compilation to never finish, thus Make never knows to build the binary files, thus deadlocking everything.
$(DEPSDIR)/%.d: $(SRCDIR)/%.asm dummy
	@echo Building deps file $@
	@$(MKDIR) -p $(DEPSDIR)
	@$(MKDIR) -p $(OBJDIR)
	set -e; \
	$(RGBASM) -M $@.tmp $(ASFLAGS) -o $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$<) $<; \
	sed 's,\($*\)\.o[ :]*,\1.o $@: ,g' < $@.tmp > $@; \
	rm $@.tmp

# Include (and potentially remake) all dependency files
include $(patsubst $(SRCDIR)/%.asm,$(DEPSDIR)/%.d,$(ASMFILES))


# How to make the ROM
$(ROMFILE): $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))
	@$(MKDIR) -p $(BINDIR)

	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm

	$(RGBLINK) $(LDFLAGS) -o $(BINDIR)/tmp.gb -m $(@:.$(ROMExt)=.map) -n $(@:.$(ROMExt)=.sym) $^ $(OBJDIR)/build_date.o
	$(RGBFIX) $(FXFLAGS) $(BINDIR)/tmp.gb

	mv $(BINDIR)/tmp.gb $@

# How to make the objects files
# (Just in case; since generating the deps files also generates the OBJ files, this should not be run ever, unless the OBJ files are destroyed but the deps files aren't.)
$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@$(MKDIR) -p $(OBJDIR)
	$(RGBASM) $(ASFLAGS) -o $@ $<

