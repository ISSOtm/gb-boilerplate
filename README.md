# gb-boilerplate
A customizable, ready-to-compile boilerplate for Game Boy RGBDS projects.


## Downloading
You can simply clone the repository using Git, or if you just want to download this, click the green `Clone or download` button up and to the right of this.

## Setting up
Make sure you have [RGBDS](https://github.com/rednex/rgbds) and Make installed. (GNU Make might be a requirement, but I'm not sure.) Python 3 is required for some tools.

## Customizing
Edit `Makefile.conf` to customize most things specific to the project (like the game name, file name and extension, etc.). Everything is commented.

Everything in the `src` folder is the source, and can be freely modified however you want. The basic structure in place should hint you at how things are organized. If you want to create a new "module" (such as the existing `home`, `engine`, `memory`...), you simply need to drop a `.asm` file in the `src` directory (name does not matter). All files in that root directory will be compiled individually.

The file at `src/res/build_date.asm` is compiled individually to include a build date in your ROM. Always comes in handy, and also displayed in the bundled error screen.

If you want to add resources, I recommend using the `res` folder: create one folder per resource, create a `Makefile` inside, and have it explain how to generate the needed resource. (Most likely a binary file.) If file `foo.bar` exists, a built-in rule exists to generate `foo.bar.pb16`, by compressing the file using PB16 (a variation of [PackBits](https://wiki.nesdev.com/w/index.php/Tile_compression#PackBits)).

## Compiling
Simply put yourself in the root directory of this project, and run the command `make`. This should create a bunch of things, including the output in the `bin` folder.

If you get errors that you don't understand, try running `make clean`. If that gives the same error, try deleting the `deps` folder. If that still doesn't work, try deleting the `bin` and `obj` folders as well. If that still doesn't work, you probably did something wrong yourself.

