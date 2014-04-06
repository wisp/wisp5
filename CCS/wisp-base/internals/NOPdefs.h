#ifndef __MSPGCC__

#define twoNOPs\
        NOP;\
        NOP;

#define NOPx2\
        NOP;\
        NOP;

#define NOPx3\
        NOP;\
        NOP;\
        NOP;

#define NOPx4\
        NOPx2;\
        NOPx2;

#define NOPx5\
        NOPx4;\
        NOP;

#define NOPx6\
        NOPx5;\
        NOP;

#define NOPx7\
        NOPx5;\
        NOPx2;

#define NOPx9\
        NOPx5;\
        NOPx4;

#define NOPx10\
        NOPx5;\
        NOPx5;

#define NOPx11\
        NOPx10;\
        NOP;

#define NOPx13\
        NOPx10;\
        NOPx3;

#define NOPx14\
        NOPx10;\
        NOPx3;

#define NOPx15\
        NOPx10;\
        NOPx5;

#define NOPx18\
        NOPx15;\
        NOPx3;

#define NOPx20\
        NOPx10;\
        NOPx10;

#define NOPx22\
        NOPx20;\
        NOPx2;

#define NOPx23\
        NOPx22;\
        NOP;

#define NOPx25\
        NOPx15;\
        NOPx10;

#define NOPx29\
        NOPx25;\
        NOPx4;

#define NOPx30\
        NOPx15;\
        NOPx10;

#define NOPx35\
        NOPx20;\
        NOPx15;

#define NOPx36\
        NOPx35;\
        NOP;

#define NOPx40\
        NOPx20;\
        NOPx20;


#else
#define MACRO(x) .macro x

MACRO(twoNOPs)
        NOP;
        NOP;
.endm

MACRO(NOPx2)
        NOP;
        NOP;
.endm

MACRO(NOPx3)
        NOP;
        NOP;
        NOP;
.endm

MACRO(NOPx4)
        NOPx2;
        NOPx2;
.endm

MACRO(NOPx5)
        NOPx4
        NOP
.endm

MACRO(NOPx6)
        NOPx5
        NOP;
.endm

MACRO(NOPx7)
        NOPx5
        NOPx2;
.endm

MACRO(NOPx9)
        NOPx5
        NOPx4;
.endm

MACRO(NOPx10)
        NOPx5;
        NOPx5;
.endm

MACRO(NOPx11)
        NOPx10;
        NOP;
.endm

MACRO(NOPx13)
        NOPx10;
        NOPx3;
.endm

MACRO(NOPx14)
        NOPx10;
        NOPx3;
.endm

MACRO(NOPx15)
        NOPx10;
        NOPx5;
.endm

MACRO(NOPx18)
        NOPx15;
        NOPx3;
.endm

MACRO(NOPx20)
        NOPx10;
        NOPx10;
.endm

MACRO(NOPx22)
        NOPx20;
        NOPx2;
.endm

MACRO(NOPx23)
        NOPx22;
        NOP;
.endm

MACRO(NOPx25)
        NOPx15;
        NOPx10;
.endm

MACRO(NOPx29)
        NOPx25;
        NOPx4;
.endm


MACRO(NOPx30)
        NOPx15;
        NOPx10;
.endm

MACRO(NOPx35)
        NOPx20;
        NOPx15;
.endm

MACRO(NOPx36)
        NOPx35;
        NOP
.endm

MACRO(NOPx40)
        NOPx20;
        NOPx20;
.endm


#endif
