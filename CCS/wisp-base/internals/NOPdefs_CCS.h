twoNOPs .macro
        NOP
        NOP
        .endm   

NOPx2   .macro
        NOP;
        NOP;
        .endm

NOPx3   .macro
        NOP;
        NOP;
        NOP;
        .endm

NOPx4   .macro
        NOPx2
        NOPx2
        .endm
        
NOPx5   .macro
        NOPx4
        NOP
        .endm

NOPx6   .macro
        NOPx5
        NOP;
        .endm

NOPx7   .macro
        NOPx5
        NOPx2;
        .endm

NOPx9   .macro
        NOPx5
        NOPx4;
        .endm
        
NOPx10  .macro
        NOPx5;
        NOPx5;
        .endm

NOPx11  .macro
        NOPx10;
        NOP;
        .endm
          
NOPx13  .macro
        NOPx10;
        NOPx3;
        .endm
          
NOPx14  .macro
        NOPx10;
        NOPx3;
        .endm

NOPx15  .macro
        NOPx10;
        NOPx5;
        .endm
 
NOPx18  .macro
        NOPx15;
        NOPx3;
        .endm
        
NOPx20  .macro
        NOPx10;
        NOPx10;
        .endm

NOPx22  .macro
        NOPx20;
        NOPx2;
        .endm

NOPx23  .macro
        NOPx22;
        NOP;
        .endm

NOPx25  .macro
        NOPx15;
        NOPx10;
        .endm

NOPx29  .macro
        NOPx25;
        NOPx4;
        .endm


NOPx30  .macro
        NOPx15;
        NOPx10;
        .endm

NOPx35  .macro
        NOPx20;
        NOPx15;
        .endm
        
NOPx36  .macro
        NOPx35;
        NOP
        .endm
        
NOPx40  .macro      
        NOPx20;
        NOPx20;
        .endm
        
