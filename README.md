# cpm-du

Version 0.1b, May 2023, Kevin Boone

## What is this?

`cpm-du` is a file storage reporter for CP/M, loosely modeled on the
Unix `du` utility. It reports the number of files, the number of
disk blocks, and the total size, of files that match a pattern. It's
written entirely in Z80 assembly language, to keep the total program
size down to ~2 kB. 

## Usage

   du {/dhv} {file patterns...}

`du /h` for details of the command-line switches. Switches can be 
given together or as separate arguments; the switch character is 
either "/" or "-".

## Examples


    A> du 

Show totals for all files on the current drive.

    A> du b:

Show totals for all files on drive B.

    A> du d:*.asm

Show totals for all files that match the pattern. 

Giving the `/d` (details) switch will make `du` report the 
sizes of individual files, rather than just a total.

## Building

I wrote this utility to be built on CP/M using the Microsoft
Macro80 assembler and Link80 linker. These are available from here:

http://www.retroarchive.org/cpm/lang/m80.com
http://www.retroarchive.org/cpm/lang/l80.com

Assemble all the `.asm` files to produce `.rel` files, then feed all
the `.rel` files into the linker. See the Makefile (for Linux) for
the syntax for these commands. There is no `make` for CP/M, so far as I
know, so building on a real CP/M machine is a bit of a tedious process.


## Limitations

`cpm-du` can't cope with a drive that contains more than 64k records in
files (about 5Mb). Such a thing is rare on a real, floppy-disk CP/M
system, but probably commonplace in an emulator. This limitation exists
to save the need to include any arithmetic routines that can handle
greater than 16-bit values. 

The utility has to store at least some information about every file
that is listed. Unfortunately, CP/M BDOS does not support interleaving
file enumeration with any other kind of file operation, even getting
the file size. So file data has to be stored in memory. In a CP/M 
system with 64k RAM, `cpm-du` will cope with up to about 1200 files in
a particular drive. Again, unlikely in a real machine, but possible
in an emulator.

Although `cpm-du` accepts filenames and patterns in short form
("foo.bar" or "a:\*.com"), it displays them in CP/M format
(upper-case, padded with spaces). Leaving out the routine that converts
from the one format to the other saves a couple of hundred bytes from
the program size.

Files that can be enumerated by BDOS, but then not opened for 
reading, still count towards the total file count, but not to the record
count.

## Legal and copying

This code is distributed under the terms of the GNU Public Licence, v3.0, 
in the hope that maybe somebody will find it useful. All the code
is original. There is no warranty of any kind.

## Revisions

May 23 2023: fixed a bug where some file open operations seemed to fail, 
because the return value from `F_OPEN` was 1-3, not 0. Fixed a bug
where the filenames were garbled because the MSB in the name was
set to indicate an attribute.



