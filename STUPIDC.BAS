DECLARE SUB mod.include (args() AS ANY)
DECLARE SUB os.free (h AS INTEGER)
DECLARE FUNCTION os.reserve% ()
'$INCLUDE: 'A:\GLOBAL.BAS'

DIM SHARED blanksymbol AS symbol
DIM SHARED symbols(100) AS symbol
DIM SHARED outp AS symbol
DIM SHARED vars(100) AS vars
DIM SHARED os(100) AS STRING

DIM SHARED nl AS STRING * 1
nl = CHR$(10)

CLS
PRINT ">>>> Loading file..."
a$ = loadfile$("A:\SAMPLE.SC")

PRINT ">>>> Running stage 1..."
b$ = preprocess$(a$)

PRINT ">>>> Running stage 2..."
parse b$

PRINT ">>>> Compilation finished."
PRINT asmoutput$

FUNCTION addlabel$ STATIC
  labels& = labels& + 1
  IF labels& = 0 THEN PRINT "ERROR> addlabel: too many labels! this may create problems with the assembler."
  addlabel$ = LTRIM$(RTRIM$(STR$(labels&)))
END FUNCTION

FUNCTION addsymbol& (symbol AS symbol)
  DO: i& = i& + 1: LOOP UNTIL (ASC(symbols(i&).name) = 32) OR (i& >= UBOUND(symbols))
  IF i& >= UBOUND(symbols) THEN PRINT "ERROR> addsymbol: Out of space for symbol '"; symbol.name; "'": EXIT FUNCTION
  symbols(i&) = symbol
  addsymbol& = i&
END FUNCTION

SUB debug.dumpkeys
  SHARED keys AS scs

  PRINT "keys.s:"
  FOR i% = 0 TO UBOUND(keys.s)
    IF ASC(keys.s(i%).key) THEN PRINT "key:"; keys.s(i%).key; " value:"; RTRIM$(keys.s(i%).value)
  NEXT

  PRINT : PRINT "keys.n:"
  FOR i% = 0 TO UBOUND(keys.n)
    IF ASC(keys.n(i%).key) THEN PRINT "key:"; keys.n(i%).key; " value:"; keys.n(i%).value
  NEXT
END SUB

SUB debug.dumpos
  PRINT "os:"
  FOR i% = 0 TO UBOUND(os)
    PRINT LEFT$(os(i%), 10);
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
  EXIT FUNCTION
END FUNCTION

SUB mod.asm (args() AS symbol)
  os(outp.outp) = os(args(0).outp)
END SUB

SUB mod.def (args() AS symbol)
  DO: i& = i& + 1: LOOP UNTIL (ASC(vars(i&).name) = 32) OR (i& >= UBOUND(vars))
  IF i& > UBOUND(vars) THEN PRINT "ERROR> mod.def: Out of variable space for variable '"; args(0).name; "'"
  vars(i&).name = args(0).name
  vars(i&).address = vars(i& - 1).address + 1
  os(outp.outp) = ""
END SUB

SUB mod.halt (args() AS symbol)
  os(outp.outp) = " JMP *"
END SUB

SUB mod.if (args() AS symbol)
  label$ = addlabel
  IF args(0).type = "?" THEN
      SELECT CASE args(0).return
        CASE "+Z"
          os(outp.outp) = os(args(0).outp) + " BNE " + label$ + os(args(1).outp) + label$ + ":"

        CASE "-Z"
          os(outp.outp) = os(args(0).outp) + " BEQ " + label$ + os(args(1).outp) + label$ + ":"

        CASE "+C"
          os(outp.outp) = os(args(0).outp) + " BCC " + label$ + os(args(1).outp) + label$ + ":"

        CASE "-C"
          os(outp.outp) = os(args(0).outp) + " BCS " + label$ + os(args(1).outp) + label$ + ":"

      END SELECT

    ELSE
      os(outp.outp) = os(args(0).outp) + " BNE " + label$ + os(args(1).outp) + label$ + ":"
  END IF
END SUB

SUB mod.include (args() AS symbol)
  IF args(0).type <> CHR$(34) THEN
    PRINT "ERROR> mod.include: Cannot accept type '"; args(0).type; "'"
    EXIT SUB
  END IF

  PRINT "INFO> mod.include: Loading file '"; os(args(0).outp); "'"
  os(outp.outp) = ""
  a$ = loadfile$(os(args(0).outp))
  parse a$
  PRINT "INFO> mod.include: Exiting include '"; os(args(0).outp); "'"
END SUB

SUB mod.sub (args() AS symbol)
  lbl$ = addlabel
  os(args(2).outp) = lbl$
  args(2).type = "$"
  args(2).name = "$" + os(args(0).outp)
  sr& = addsymbol(args(2))
  os(outp.outp) = lbl$ + ":" + os(args(1).outp) + " RTS"
END SUB

SUB mod.system (args() AS symbol)
  IF args(0).type <> CHR$(34) THEN
    PRINT "ERROR> mod.system: Cannot use type '"; args(0).type; "'"
    EXIT SUB
  END IF

  scs.load os(args(0).outp)
  os(outp.outp) = ""
END SUB

SUB os.free (h AS INTEGER)
  os(h) = CHR$(255)
END SUB

SUB os.init
  FOR i% = 0 TO UBOUND(os)
    os(i%) = CHR$(255)
  NEXT
END SUB

FUNCTION os.reserve%
  FOR i% = 0 TO UBOUND(os)
    IF ASC(os(i%)) = 255 THEN

      os.reserve% = i%
      os(i%) = ""
      EXIT FUNCTION

    END IF
  NEXT

  PRINT "ERROR> os.reserve: os() is full, cannot reserve new string space!"
  os.reserve% = 0
END FUNCTION

SUB parse (pgm AS STRING)
  DIM char AS STRING * 1, args(16) AS symbol
  SHARED asmoutput$

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

          'os.free args(currentarg%).outp
          'os.free outp.outp
          'outp.outp = os.reserve

          run.sym MID$(pgm, lastarg%, (i% - lastarg%) - 1)
          args(currentarg%) = outp

          lastarg% = i% - 1
          currentarg% = currentarg% + 1

        END IF

      CASE ";"
        IF level% = 0 THEN GOSUB runcmd 'end of statement

    END SELECT
    IF level% = -1 THEN EXIT FOR
  NEXT
  EXIT SUB

runcmd:
    os.free args(currentarg%).outp
    args(currentarg%).outp = os.reserve
    run.sym MID$(pgm, lastarg%, (i% - lastarg%) - 1)'Final argument
    args(currentarg%) = outp
    lastarg% = i% - 1

    run.mod symname$, args()
    asmoutput$ = asmoutput$ + os(outp.outp)
    os(outp.outp) = ""

    symname$ = ""
    'ERASE args
    currentarg% = 0
    pgm = MID$(pgm, i% + 1)
    i% = 1

  RETURN
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
  IF ASC(module$) = ASC("$") THEN run.mod.sub MID$(module$, 2), args()
  PRINT module$
  SELECT CASE module$
    CASE "if": mod.if args()

    'CASE "while": mod.while args()

    CASE "sub": mod.sub args()

    'CASE "func": mod.func args()
                
    CASE "def": mod.def args()

    CASE "asm": mod.asm args()

    CASE "halt": mod.halt args()

    CASE "system": mod.system args()

    CASE "include": mod.include args()

    CASE ELSE: PRINT "ERROR> run.mod: invalid module '"; module$; "'"
  END SELECT
END SUB

SUB run.mod.sub (subname$, args() AS symbol)
  FOR i% = 0 TO UBOUND(symbols)

    IF symbols(i%).name = subname$ GOTO runsub
    
  NEXT
  PRINT "ERROR> run.mod.sub: Cannot locate subroutine '"; subname$; "'"
                        
runsub:
  s% = i%
  i% = 0
  DO
    SELECT CASE ASC(args(i%).type)
      CASE ASC("#")
        os(outp.outp) = os(outp.outp) + " PUSH #" + LTRIM$(STR$(args(i%).value))

      CASE ASC("*")

      CASE ASC("%")
        os(outp.outp) = os(outp.outp) + " PUSH" + STR$(args(i%).value)

      CASE ELSE
        PRINT "ERROR> run.mod.sub: Cannot use type '"; args(i%).type; "' in a sub/function"
        EXIT DO
    END SELECT
    i% = i% + 1
  LOOP

END SUB

SUB run.sym (code$)
  outp.type = LEFT$(code$, 1)
  symname$ = MID$(code$, 2)

  SELECT CASE outp.type
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
            os(outp.outp) = MID$(symname$, 2, LEN(symname$) - 2)
                          
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
            os(outp.outp) = LTRIM$(RTRIM$(STR$(vars(i%).address)))
            outp.name = symname$
            EXIT FOR

          END IF
        NEXT


      CASE "{"
        parse symname$

      CASE "&"
        os(outp.outp) = symname$
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

