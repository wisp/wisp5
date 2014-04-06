CC=msp430-gcc
CFLAGS=-mmcu=msp430fr5969 -Iinclude

CFILES    = $(wildcard *.c)
CFILES   += $(wildcard comm/*.c)
CFILES   += $(wildcard math/*.c)
CFILES   += $(wildcard sensors/*.c)
CFILES   += $(wildcard timing/*.c)
CFILES   += $(wildcard internals/*.c)
OBJS      = $(CFILES:.c=.o)
ASMFILES += $(wildcard math/*.asm)
ASMFILES  = $(wildcard rfid/*.asm)
OBJS     += $(ASMFILES:.asm=.o)
DEPS      = $(CFILES:.c=.d)

PERL      = perl

all: wisp5.elf

-include $(DEPS)

wisp5.elf: $(DEPS) $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

%.d: %.c
	@set -e; rm -f $@; \
		$(CC) $(CFLAGS) -MM -MP $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$

%.o: %.c %.d
	$(CC) $(CFLAGS) -c -o $@ $<

%.S: %.asm ccs2mspgcc.pl
	$(PERL) ccs2mspgcc.pl $< > $@

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) wisp5.elf $(OBJS) $(DEPS)
