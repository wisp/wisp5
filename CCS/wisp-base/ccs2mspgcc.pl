#!/usr/bin/env perl
#
# Convert a CCS assembly source file to mspgcc assembly, line by line.
#
# TODO: Improve readability of terrifying inscrutable regular expressions.
#

sub main () {
    my %defines;

    # filter the source program line-by-line
    while (<>) {
        $suppress_print = 0;

        # .cdecls C,LIST, "foo.h" -> #include "foo.h"
        # .cdecls C,LIST, "foo.h", "bar.h" -> #include "foo.h"\n#include "bar.h"
        if (/^\s*\.cdecls\s+C,\s*LIST,\s*(("([^"]+)"(,\s*)?)+)(.*)$/) {
            $suppress_print = 1;
            my @includes = split /,\s*/, $1;
            foreach my $include (@includes) {
                print "#include $include\n";
            }
        }

        # .define "bar", FOO
        if (s/^\s*\.define\s+"([^"]+)",\s*(\w+).*$/#define $2 $1/) {
            $defines{$2} = $1;
        }

        # .include "bar"
        s/^\s*\.include\s+"([^"]+)".*$/#include "$1"/;

        # hack: remove _CCS from included header filenames to get non-CCS
        # versions (which may or may not exist)
        if (/^\s*#include/) {
            s/_CCS\.h\b/\.h/;
        }

        # foo .set R5 -> .set foo, R5
        # (and capture the definition in %defines for later substitutions)
        if (s/^\s*(\w+)\s+\.set\s+(R\d+)(\s*.*)/.set $1, $2$3\n/) {
            $defines{$1} = $2;
        }

        # .def foo, bar -> (nothing)
        s/^\s*\.def\s+.*$//;

        # .ref foo -> (nothing)
        s/^\s*\.ref\s+.*$//;

        # .retain[refs] -> (nothing)
        s/^\s*\.retain(refs)?\s+.*$//;

        # #NNNNh -> #0xNNNN
        s/#([[:xdigit:]]+)h/#0x$1/;

        # OP SRC, N(foo) -> OP SRC, N(Rn)
        # OP SRC, bar(foo) -> OP SRC, bar(Rn)
        s/^(\s+)([A-Z\.]+)\s+([^,]+),\s*(([\w-]+)\((\w+)\))(\s*.*)/"$1$2 $3, " . ($defines{$5} ne '' ? $defines{$5} : $5) . "(" . ($defines{$6} || $6) . ")$7"/e;

        # OP N(foo), DEST -> OP N(Rn), DEST
        # OP bar(foo), DEST -> OP bar(Rn), DEST
        s/^(\s+)([A-Z\.]+)\s+(([\w-]+)\((\w+)\)),\s*([^,]+)(\s*.*)/"$1$2 " . ($defines{$4} ne '' ? $defines{$4} : $4) . "(" . ($defines{$5} || $5) . "), $6$7"/e;

        # OP SRC, N(SP) -> OP SRC, N(R1)
        # OP SRC, N(SR) -> OP SRC, N(R2)
        s/^(\s+)([A-Z\.]+)\s+([^,]+),\s*(([\d-]+)\(SP\))(\s*.*)/$1$2 $3, $5(R1)$6/;
        s/^(\s+)([A-Z\.]+)\s+([^,]+),\s*(([\d-]+)\(SR\))(\s*.*)/$1$2 $3, $5(R2)$6/;

        # OP N(SP), DEST -> OP N(R1), DEST
        # OP N(SR), DEST -> OP N(R2), DEST
        s/^(\s+)([A-Z\.]+)\s+(([\d-]+)\(SP\)),\s*([^,]+)(\s*.*)/$1$2 $4(R1), $5$6/;
        s/^(\s+)([A-Z\.]+)\s+(([\d-]+)\(SR\)),\s*([^,]+)(\s*.*)/$1$2 $4(R2), $5$6/;

        # OP #(X+Y), DEST -> OP X+Y, DEST
        # (generate a temporary symbol so the preprocessor can do the arithmetic
        # in the X+Y expression, and include that instead of the expression)
        if (/^(\s+)([A-Z\.]+)\s+#\(([^\)]+\s*[~\+\-|&]\s*[^\)]+)\)\s*,\s*([^\s]+)(\s*.*)/) {
            $suppress_print = 1;
            print "#define __TMPSYM $3\n";
            print "$1$2 #__TMPSYM, $4$5\n";
            print "#undef __TMPSYM\n";
        }

        # NOPxN -> NOP NOP ... NOP
        if (/^(\s+)NOPx(\d+)(\s*.*)/) {
            $suppress_print = 1;
            for (my $i = 0; $i < int($2); $i++) {
                print "$1NOP\n";
            }
        }

        print unless $suppress_print;
    }

    return 0;
}

exit(&main());
