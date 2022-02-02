# Makefile for cpm-du
# Kevin Boone, Feb 2022
# Set the path to the CPM emulator. 
# Obtain it from here: https://github.com/jhallen/cpm
CPM=cpm

# Define the assembler and linker. Get Macro80 and Link80 from here:
# http://www.retroarchive.org/cpm/lang/m80.com
# http://www.retroarchive.org/cpm/lang/l80.com
MACRO80=m80
LINK80=l80

TARGET=du.com

all: $(TARGET)

ma.rel: main.asm conio.inc clargs.inc string.inc bdos.inc files.inc bdmem.inc initfcb.inc mem.inc 
	$(CPM) $(MACRO80) ma.rel=main.asm

co.rel: conio.asm bdos.inc
	$(CPM) $(MACRO80) co.rel=conio.asm

me.rel: mem.asm
	$(CPM) $(MACRO80) me.rel=mem.asm

db.rel: dbgutl.asm conio.inc
	$(CPM) $(MACRO80) db.rel=dbgutl.asm

im.rel: intmath.asm 
	$(CPM) $(MACRO80) im.rel=intmath.asm

st.rel: string.asm intmath.inc
	$(CPM) $(MACRO80) st.rel=string.asm

fl.rel: files.asm bdos.inc initfcb.inc
	$(CPM) $(MACRO80) fl.rel=files.asm

cl.rel: clargs.asm mem.inc
	$(CPM) $(MACRO80) cl.rel=clargs.asm

bm.rel: bdmem.asm bdos.inc
	$(CPM) $(MACRO80) bm.rel=bdmem.asm

if.rel: initfcb.asm mem.inc string.inc bdos.inc
	$(CPM) $(MACRO80) if.rel=initfcb.asm

e.rel: end.asm 
	$(CPM) $(MACRO80) e.rel=end.asm

# Note that in the linker command line, main (ma.rel) must come first, and
#   end (e.rel) must come last. main contains the first statements of the
#   program, at 0x100, and end contains the "endprog" symbol that is used
#   to work out the start of heap 
$(TARGET): ma.rel co.rel db.rel im.rel st.rel me.rel if.rel cl.rel fl.rel bm.rel e.rel
	$(CPM) $(LINK80) ma,co,bm,db,im,st,me,if,cl,fl,e,du/n/e

clean:
	rm -f $(TARGET) *.rel

