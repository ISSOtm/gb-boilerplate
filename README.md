# gb-boilerplate

A minimal, customizable, ready-to-compile boilerplate for Game Boy RGBDS projects.

## Downloading

You can simply clone the repository using Git, or if you just want to download this, click the `Clone or download` button up and to the right of this. This repo is also usable as a GitHub template for creating new repositories.

## Setting up

Make sure you have [RGBDS](https://github.com/rednex/rgbds), at least version 0.4.0, and GNU Make installed. Python 3 is required for the PB16 compressor bundled as a usage example, but that script is optional.

## Customizing

Edit `project.mk` to customize most things specific to the project (like the game name, file name and extension, etc.).
Everything has accompanying doc comments.

Everything in the `src` directory is the source, and can be freely modified however you want.
Any `.asm` files in that directory (and its sub-directories, recursively) will be individually assembled, automatically.
If you need some files not to be assembled directly (because they are only meant to be `INCLUDE`d), you can either rename them (typically, to `.inc`), or move them outside of `src` (typically, to a directory called `include`).

The file at `src/assets/build_date.asm` is compiled individually to include a build date in your ROM.
Always comes in handy.

If you want to add resources, I recommend using the `src/assets` directory.
Add rules in the Makefile; an example is provided for compressing files using PB16 (a variation of [PackBits](https://wiki.nesdev.com/w/index.php/Tile_compression#PackBits)).

## Compiling

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`.
This should create a bunch of things, including the output in the `bin` directory.

Pass the `-s` flag to `make` if it spews too much input for your tastes.
Päss the `-j <N>` flag to `make` to build more things in parallel, replacing `<N>` with however many things you want to build in parallel; your number of (logical) CPU cores is often a good pick (so, `-j 8` for me), run the command `nproc` to obtain it.

If you get errors that you don't understand, try running `make clean`.
If that gives the same error, try deleting the `assets` directory.
If that still doesn't work, try deleting the `bin` and `obj` directories as well.
If that still doesn't work, feel free to ask for help.

## See also

If you want something less barebones, already including some "base" code, check out [gb-starter-kit](https://github.com/ISSOtm/gb-starter-kit).

Perhaps [a gbdev style guide](https://gbdev.io/guides/asmstyle) may be of interest to you?

I recommend the [BGB](https://bgb.bircd.org) emulator for developing ROMs on Windows and, via Wine, Linux and macOS (64-bit build available for Catalina).
[SameBoy](https://github.com/LIJI32/SameBoy) is more accurate, but has a more lackluster interface outside of macOS.

### Libraries

- [Variable-width font engine](https://github.com/ISSOtm/gb-vwf)
- [Structs in RGBDS](https://github.com/ISSOtm/rgbds-structs)
