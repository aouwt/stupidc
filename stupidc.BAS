TYPE symbol
    name AS STRING
    type AS STRING * 1
    value AS INTEGER
    return AS STRING * 2
    outp AS STRING
END TYPE

TYPE vars
    name AS STRING
    address AS INTEGER
END TYPE

DIM SHARED blanksymbol AS symbol, symbols(100) AS symbol, outp AS symbol, vars(100) AS vars

CLS

p$ = "$thissubdoesnotexist(#'Hello, World!',#'Hello, world!');"

o$ = preprocess$(p$)
'$INCLUDE:'stupidc_modules.bas'


FUNCTION addlabel$ STATIC
    labels& = labels& + 1
    IF labels& = 0 THEN PRINT "ERR> addlabel: too many labels! this may create problems with the assembler."
    addlabel$ = LTRIM$(RTRIM$(STR$(labels&)))
END FUNCTION

FUNCTION addsymbol& (symbol AS symbol)
    DO: i& = i& + 1: LOOP UNTIL symbols(i&).name = ""
    symbols(i&) = symbol
    addsymbol& = i&
END FUNCTION

SUB assemble (c$)
    DIM f AS INTEGER

    PRINT "INF> assemble: Saving ASM output in C:\stupidC\outp.asm...";

    f = FREEFILE
    OPEN "C:\stupidC\outp.asm" FOR OUTPUT AS #f
    PRINT #f, c$
    CLOSE #f

    PRINT "done"
    PRINT "INF> assemble: Running ACME"
    PRINT "INF> assemble: C:\ACME091\ACME --outfile ./output.rom --format plain --cpu 6502 C:/stupicC/outp.asm"
    PRINT

    SHELL "C:\ACME091\ACME --outfile ./output.rom --format plain --cpu 6502 C:/stupidC/outp.asm"

    PRINT "INF> assemble: ACME done."
END SUB


SUB parse (line$)
    DIM char AS STRING * 1

END SUB

FUNCTION preprocess$ (program AS STRING)
    DIM c AS STRING * 1, n AS STRING * 1
    PRINT "INF> preprocess: Running stage 1..."

    FOR i& = 1 TO LEN(program)
        c = MID$(program, i&, 1)
        SELECT CASE ASC(c)

            CASE 34, 39
                i2& = INSTR(i& + 1, program, c)
                IF i2& = 0 THEN
                    PRINT "FAT> preprocess: could not find closing quotation! aborting."
                    PRINT MID$(program, i& - 5, 10) ';"..."; RIGHT$(program, 5) '
                    PRINT SPACE$(5); "^"
                    PRINT "Make sure to terminate literal strings with `'` or `" + CHR$(34) + "`!"
                    END
                    'SYSTEM
                END IF

                o$ = o$ + MID$(program, i&, i2& - i&)
                i& = i2&

            CASE 33 TO 255: o$ = o$ + c

        END SELECT
    NEXT
    PRINT "INF> preprocess: Running stage 2..."
    preprocess$ = o$
END FUNCTION

SUB run.mod (module$, args() AS symbol)
    SELECT CASE modules$
        CASE "if": mod.if args()
            'CASE "while": mod.while args()
        CASE "sub": mod.sub args()
            'CASE "func": mod.func args()
        CASE "def": mod.def args()
        CASE "asm": mod.asm args()
            'case "mem":mod.mem args()
        CASE "const": mod.const args()
        CASE "null":
        CASE ELSE
            PRINT "ERR> modrun: invalid module '"; module$; "'"
    END SELECT
END SUB

SUB run.sym (symname$)
    SELECT CASE LEFT$(symname$, 1)
        CASE "$"
            'symmod.sub symname$
        CASE "#"
            SELECT CASE MID$(symname$, 2, 1)
                CASE "$"
                    outp.value = VAL("&H" + MID$(symname$, 3))
                CASE "%"
                    outp.value = VAL("&B" + MID$(symname$, 3))
                CASE "&"
                    outp.value = VAL("&O" + MID$(symname$, 3))
                CASE ELSE
                    IF LTRIM$(RTRIM$(STR$(VAL(MID$(symname$, 2))))) = MID$(symname$, 2) THEN
                        outp.value = VAL(MID$(symname$, 2))
                    ELSE
                        PRINT "ERR> runsymbol: '"; symname$; "' when expected decimal number"
                    END IF
            END SELECT
        CASE "*"
            'symmod.func symname$
        CASE "?"
            'symmod.bool symname$
        CASE "%"
            'fetchvar symname$
        CASE "{"
            'parse symname$
        CASE "&"
            outp.name = MID$(symname$, 2)
        CASE ELSE
            PRINT "ERR> runsymbol: cannot determine type of symbol '"; symname$; "'"

    END SELECT
END SUB

