DECLARE SUB parse (pgm AS STRING)
DECLARE FUNCTION loadfile$ (filename$)
DECLARE SUB mod.system (args() AS ANY)
DECLARE SUB scs.load (filename$)
DECLARE FUNCTION crop$ (s AS STRING)
DECLARE FUNCTION scs.getStrKey$ (key$)
DECLARE FUNCTION scs.getNumKey! (key$)
DECLARE SUB run.mod (module$, args() AS ANY)
DECLARE FUNCTION addlabel$ ()
DECLARE FUNCTION addsymbol& (symbol AS ANY)
DECLARE FUNCTION postprocess$ (c$)
DECLARE FUNCTION preprocess$ (program AS STRING)
DECLARE SUB run.sym (code$)
DECLARE SUB mod.asm (args() AS ANY)
DECLARE SUB mod.def (args() AS ANY)
DECLARE SUB mod.halt (args() AS ANY)
DECLARE SUB mod.if (args() AS ANY)
DECLARE SUB mod.sub (args() AS ANY)

TYPE symbol
    name AS STRING * 16
    type AS STRING * 1
    value AS INTEGER
    return AS STRING * 2
    outp AS STRING * 512
END TYPE

TYPE vars
    name AS STRING * 16
    address AS INTEGER
END TYPE

TYPE scsStringKey
    key AS STRING * 16
    value AS STRING * 512
END TYPE

TYPE scsNumberKey
    key AS STRING * 16
    value AS SINGLE
END TYPE

TYPE scs
    s(32) AS scsStringKey
    n(32) AS scsNumberKey
END TYPE

DIM SHARED blanksymbol AS symbol
DIM SHARED symbols(100) AS symbol
DIM SHARED outp AS symbol
DIM SHARED vars(100) AS vars

CLS
PRINT "Loading file..."
a$ = loadfile$("C:\SAMPLE.SC")

PRINT "Running stage 1..."
b$ = preprocess$(a$)

PRINT "Running stage 2..."
parse b$

FUNCTION addlabel$ STATIC
    labels& = labels& + 1
    IF labels& = 0 THEN PRINT "ERROR> addlabel: too many labels! this may create problems with the assembler."
    addlabel$ = LTRIM$(RTRIM$(STR$(labels&)))
END FUNCTION

FUNCTION addsymbol& (symbol AS symbol)
    DO: i& = i& + 1: LOOP UNTIL symbols(i&).name = ""
    symbols(i&) = symbol
    addsymbol& = i&
END FUNCTION

SUB debug.dumpkeys
    SHARED keys AS scs

    PRINT "keys.s:"
    FOR i% = 0 TO UBOUND(keys.s)
        IF ASC(keys.s(i%).key) THEN PRINT "key:"; keys.s(i%).key; " value:"; RTRIM$(keys.s(i%).value)
    NEXT

    'PRINT
    PRINT : PRINT "keys.n:"
    FOR i% = 0 TO UBOUND(keys.n)
        IF ASC(keys.n(i%).key) THEN PRINT "key:"; keys.n(i%).key; " value:"; keys.n(i%).value
    NEXT
END SUB

FUNCTION loadfile$ (filename$)
    f% = FREEFILE
    OPEN filename$ FOR BINARY AS #f%
    DIM c AS STRING * 1
    DO
        GET #f%, , c
        s$ = s$ + c
    LOOP UNTIL EOF(f%)
    loadfile$ = s$
    CLOSE #f%
END FUNCTION

SUB mod.asm (args() AS symbol)
    outp.outp = RTRIM$(args(0).outp)
END SUB

SUB mod.def (args() AS symbol)
    DO: i& = i& + 1: LOOP UNTIL vars(i&).name = ""
    vars(i&).name = args(0).name
    vars(i&).address = vars(i& - 1).address + 1
END SUB

SUB mod.halt (args() AS symbol)
    outp.outp = " JMP *"
END SUB

SUB mod.if (args() AS symbol)
    label$ = addlabel
    IF args(0).type = "?" THEN
        SELECT CASE args(0).return
            CASE "+Z"
                outp.outp = RTRIM$(args(0).outp) + " BNE " + label$ + RTRIM$(args(1).outp) + label$ + ":"

            CASE "-Z"
                outp.outp = RTRIM$(args(0).outp) + " BEQ " + label$ + RTRIM$(args(1).outp) + label$ + ":"

            CASE "+C"
                outp.outp = RTRIM$(args(0).outp) + " BCC " + label$ + RTRIM$(args(1).outp) + label$ + ":"

            CASE "-C"
                outp.outp = RTRIM$(args(0).outp) + " BCS " + label$ + RTRIM$(args(1).outp) + label$ + ":"

        END SELECT
    ELSE
        outp.outp = RTRIM$(args(0).outp) + " BNE " + label$ + RTRIM$(args(1).outp) + label$ + ":"
    END IF
END SUB

SUB mod.sub (args() AS symbol)
    lbl$ = addlabel
    args(2).outp = lbl$
    args(2).type = "$"
    args(2).name = "$" + RTRIM$(args(0).outp)
    sr& = addsymbol(args(2))
    outp.outp = lbl$ + ":" + RTRIM$(args(1).outp) + " RTS"
END SUB

SUB mod.system (args() AS symbol)
    IF args(0).type <> CHR$(34) THEN
        PRINT "ERROR> mod.system: Cannot use type '"; args(0).type; "'"
        EXIT SUB
    END IF

    scs.load RTRIM$(args(0).outp)
END SUB

SUB parse (pgm AS STRING)
    DIM char AS STRING * 1, args(16) AS symbol

    FOR i% = 1 TO LEN(pgm)
        char = MID$(pgm, i%, 1)

        SELECT CASE char
            CASE "(": level% = level% + 1
                IF level% = 1 THEN lastarg% = i% + 1: symname$ = LEFT$(pgm, i% - 1)

            CASE ")": level% = level% - 1

            CASE "{": level% = level% + 1

            CASE "}": level% = level% - 1

            CASE ","
                IF level% = 1 THEN
                    run.sym MID$(pgm, lastarg%, (i% - lastarg%) - 1)
                    args(currentarg%) = outp
                    lastarg% = i% - 1
                    currentarg% = currentarg% + 1

                END IF

            CASE ";"
                IF level% = 0 THEN 'end of statement

                    run.sym MID$(pgm, lastarg%, (i% - lastarg%) - 1)'Final argument
                    args(currentarg%) = outp
                    lastarg% = i% - 1
                    currentarg% = currentarg% + 1

                    run.mod symname$, args()
                    symname$ = ""
                    'ERASE args
                    currentarg% = 0
                    pgm = MID$(pgm, i% + 1)
                   
                END IF

        END SELECT
    NEXT
END SUB

FUNCTION postprocess$ (c$)

END FUNCTION

FUNCTION preprocess$ (program AS STRING)
    DIM c AS STRING * 1 ', n AS STRING * 1

    FOR i& = 1 TO LEN(program)
        c = MID$(program, i&, 1)
        SELECT CASE ASC(c)

            CASE 34
                i2& = INSTR(i& + 1, program, c)
                IF i2& = 0 THEN
                    PRINT "ERROR> preprocess: could not find closing quotation!"
                    PRINT MID$(program, i& - 10, 10)
                    PRINT SPACE$(9); "^"
                ELSE 'im just gonna ignore that
                    o$ = o$ + MID$(program, i&, i2& - i& + 1)
                    i& = i2&
                END IF

            CASE ASC("<")
                i2& = INSTR(i& + 1, program, ">")
                IF i2& = 0 THEN
                    PRINT "ERROR> preprocess: could not find close of comment!"
                    PRINT MID$(program, i& - 10, 10)
                    PRINT SPACE$(9); "^"
                ELSE i& = i2&
                END IF

            CASE 33 TO 255: o$ = o$ + c

        END SELECT
    NEXT

    preprocess$ = o$
END FUNCTION

SUB run.mod (module$, args() AS symbol)
    SELECT CASE module$
        CASE "if": mod.if args()

        'CASE "while": mod.while args()

        CASE "sub": mod.sub args()

        'CASE "func": mod.func args()
        
        CASE "def": mod.def args()

        CASE "asm": mod.asm args()

        CASE "halt": mod.halt args()

        CASE "system": mod.system args()

        CASE ELSE: PRINT "ERROR> run.mod: invalid module '"; module$; "'"
    END SELECT
END SUB

SUB run.sym (code$)
    outp.type = LEFT$(code$, 1)
    symname$ = MID$(code$, 2)

    SELECT CASE outp.type
        CASE "$"
            'run.mod.sub symname$

        CASE "#"
            IF LEN(symname$) = 0 THEN PRINT "ERROR> run.sym: Lonely #. Maybe you should give it some friends.": EXIT SUB
            SELECT CASE ASC(symname$)
                CASE ASC("$")
                    outp.value = VAL("&H" + MID$(symname$, 2))

                CASE ASC("%")
                    outp.value = VAL("&B" + MID$(symname$, 2))

                CASE ASC("&")
                    outp.value = VAL("&O" + MID$(symname$, 2))

                CASE 34
                    outp.type = CHR$(34)
                    outp.outp = MID$(symname$, 2, LEN(symname$) - 2)
              
                CASE ELSE
                    IF LTRIM$(RTRIM$(STR$(VAL(symname$)))) = symname$ THEN
                        outp.value = VAL(symname$)
                      ELSE
                        PRINT "ERROR> run.sym: '#"; symname$; "' when expected decimal number"
                    END IF

            END SELECT

        CASE "*"
            'run.mod.func symname$

        CASE "?"
            'run.bool symname$

        CASE "%"
            FOR i% = 0 TO UBOUND(vars)
                IF vars(i%).name = symname$ THEN
                    outp.outp = LTRIM$(RTRIM$(STR$(vars(i%).address)))
                    outp.name = symname$
                    EXIT FOR
                END IF
            NEXT

        CASE "{"
            'parse symname$

        CASE "&"
            outp.outp = symname$
            outp.type = "&"

        CASE ELSE
            PRINT "ERROR> run.sym: cannot determine type of symbol '"; outp.type; symname$; "'"

    END SELECT
END SUB

FUNCTION scs.getNumKey! (key$)
    SHARED keys AS scs

    FOR i% = 0 TO UBOUND(keys.n)
        IF RTRIM$(keys.n(i%).key) = key$ THEN
            scs.getNumKey! = keys.n(i%).value
            EXIT FOR
        END IF
    NEXT
    IF i% = UBOUND(keys.n) THEN PRINT "ERROR> scs.getNumKey!: Key '"; key$; "' not found!"

END FUNCTION

FUNCTION scs.getStrKey$ (key$)
    SHARED keys AS scs

    FOR i% = 0 TO UBOUND(keys.s)
        IF RTRIM$(keys.s(i%).key) = key$ THEN
            scs.getStrKey$ = keys.s(i%).value
            EXIT FOR
        END IF
    NEXT
    IF i% = UBOUND(keys.s) THEN PRINT "ERROR> scs.getStrKey$: Key '"; key$; "' not found!"
END FUNCTION

SUB scs.load (filename$)
    SHARED keys AS scs
    ERASE keys.s, keys.n

    f% = FREEFILE
    PRINT "INFO> scs.load: Loading SCS file '"; filename$; "'"
    OPEN filename$ FOR INPUT AS #f%

    DO
        LINE INPUT #f%, ln$
        ln$ = LTRIM$(RTRIM$(ln$))

        i% = INSTR(ln$, " ")
        IF i% = 0 THEN GOTO nextline
        key$ = LTRIM$(RTRIM$(MID$(ln$, 2, i% - 2)))
        val$ = LTRIM$(RTRIM$(MID$(ln$, i% + 1)))
        
        IF UCASE$(val$) = "TRUE" THEN val$ = "-1"
        IF UCASE$(val$) = "FALSE" THEN val$ = "0"

        SELECT CASE ASC(ln$)
            CASE ASC("#")
                'Ignore it

            CASE ASC("=")
                FOR i% = 0 TO UBOUND(keys.n)
                    IF ASC(keys.n(i%).key) = 0 THEN
                        keys.n(i%).key = UCASE$(key$)
                        keys.n(i%).value = VAL(val$)
                        EXIT FOR
                    END IF
                NEXT
                IF i% = UBOUND(keys.n) THEN PRINT "ERROR> loadscs: Out of space for number key '"; key$; "'!"

            CASE ASC("$")
                FOR i% = 0 TO UBOUND(keys.s)
                    IF ASC(keys.s(i%).key) = 0 THEN
                        keys.s(i%).key = UCASE$(key$)
                        keys.s(i%).value = val$
                        EXIT FOR
                    END IF
                NEXT
                IF i% = UBOUND(keys.s) THEN PRINT "ERROR> loadscs: Out of space for string key '"; key$; "'!"

            CASE ASC("{")
                DO
                    LINE INPUT #f%, ln$
                    ln$ = LTRIM$(RTRIM$(ln$))
                    IF ln$ = "}" THEN EXIT DO
                    val$ = val$ + ln$ + CHR$(10) + CHR$(13)
                LOOP UNTIL EOF(f%)
                IF EOF(f%) THEN PRINT "WARN> loadscs: Unexpected EOF while reading multi-line key '"; key$; "'"

                FOR i% = 0 TO UBOUND(keys.s)
                    IF ASC(keys.s(i%).key) = 0 THEN
                        keys.s(i%).key = UCASE$(key$)
                        keys.s(i%).value = val$
                        EXIT FOR
                    END IF
                NEXT
                IF i% = UBOUND(keys.s) THEN PRINT "ERROR> loadscs: Out of space for multi-line key '"; key$; "'!"
                                                                                             
            CASE ELSE
                PRINT "ERROR> loadscs: Unknown key type '"; ASC(ln$); "'"

        END SELECT
nextline:
    LOOP UNTIL EOF(f%)
END SUB

