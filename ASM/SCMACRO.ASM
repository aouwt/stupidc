;---------------------------------------------------------------------------;
;stupidc ASM macros                                                         ;
;https://github.com/all-other-usernames-were-taken/stupidc                  ;
;                                                                           ;
;(c)2021 all-other-usernames-were-taken                                     ;
;---------------------------------------------------------------------------;

    ;Fakestack macros

    MACRO S_PUSH ;Pushes to the fakestack

        ;LDA {1}
        LDX S_PTR
        STA S_START,x
        DEC S_PTR

    ENDM



    MACRO S_PULL ;Pulls from the fakestack.

        LDX S_PTR
        LDA S_START,x
        INC S_PTR

    ENDM



    MACRO S_GET ;Gets the top item from the fakestack without decrementing
                    ;the stack pointer.
        LDX S_PTR
        LDA S_START,x

    ENDM



    MACRO S_SET ;Sets the top item from the fakestack without incrementing
                    ;the stack pointer.
        ;LDA {1}
        LDX S_PTR
        STA S_START,x

    ENDM


   
    MACRO CLEARMEM

        LDX #0
        LDA #0
.Loop:
         STA {1},x
         INX
         CPX {2}
        BNE .Loop

    ENDM

