# This file contains project configuration


# Value that the ROM will be filled with
PADVALUE := 0xFF

## Header constants (passed to RGBFIX)

# ROM version (typically starting at 0 and incremented for each published version)
VERSION := 0

# 4-ASCII letter game ID
GAMEID := BOIL

# Game title, up to 11 ASCII chars
TITLE := BOILERPLATE

# New licensee, 2 ASCII chars
# Homebrew games FTW!
LICENSEE := HB
# Old licensee, please set to 0x33 (required to get SGB compatibility)
OLDLIC := 0x33

# MBC type, tells which hardware is in the cart
# See https://gbdev.io/pandocs/#_0147-cartridge-type or consult any copy of Pan Docs
# If using no MBC, consider enabling `-t` below
MBC := 0x00

# ROM size is set automatically by RGBFIX

# Size of the on-board SRAM; MBC type should indicate the presence of RAM
# See https://gbdev.io/pandocs/#_0149-ram-size or consult any copy of Pan Docs
# Set this to 0 when using MBC2's built-in SRAM
SRAMSIZE := 0x00

# ROM name
ROMNAME := boilerplate
ROMEXT  := gb


# Compilation parameters, uncomment to apply, comment to cancel
# "Sensible defaults" are included

# Disable automatic `nop` after `halt`
ASFLAGS += -h

# Export all labels
# This means they must all have unique names, but they will all show up in the .sym and .map files
# ASFLAGS += -E

# Game Boy Color compatible
# FIXFLAGS += -c
# Game Boy Color required
# FIXFLAGS += -C

# Super Game Boy compatible
# FIXFLAGS += -s

# Game Boy mode
# LDFLAGS += -d

# No banked WRAM mode
# LDFLAGS += -w

# 32k mode
# LDFLAGS += -t
