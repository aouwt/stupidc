DECLARE SUB Run.SR (SubName$, Args() AS ANY)
DECLARE SUB test ()
DECLARE FUNCTION AddLabel$ ()
DECLARE FUNCTION AddSymbol& (Symbol AS ANY)
DECLARE FUNCTION FILEEXISTS% (Filename$)
DECLARE FUNCTION LOADFILE$ (Filename$)
DECLARE SUB LogP (t$)
DECLARE SUB Mod.Asm (Args() AS ANY)
DECLARE SUB Mod.Def (Args() AS ANY)
DECLARE SUB Mod.Halt (Args() AS ANY)
DECLARE SUB Mod.If (Args() AS ANY)
DECLARE SUB Mod.Include (Args() AS ANY)
DECLARE SUB Mod.Sub (Args() AS ANY)
DECLARE SUB Mod.System (Args() AS ANY)
DECLARE SUB Parse (Pgm AS STRING)
DECLARE FUNCTION Postprocess$ (c$)
DECLARE FUNCTION Preprocess$ (Program AS STRING)
DECLARE SUB Run.Mod (Module$, Args() AS ANY)
DECLARE SUB Run.Sym (Code$)
DECLARE SUB S.Init ()
DECLARE FUNCTION S.Reserve% ()
DECLARE FUNCTION SCS.GetNumKey! (Key$)
DECLARE FUNCTION SCS.GetStrKey$ (Key$)
DECLARE SUB SCS.Load (Filename$)
DECLARE SUB Func.Pull (Args() AS ANY)
DECLARE SUB Run.Func (Funcname$)



TYPE Symbol
  Name AS STRING * 16
  type AS STRING * 1
  Value AS INTEGER
  Return AS STRING * 2
  Outp AS INTEGER 'Location in the S() array. QB can't use variable-length strings in UDTs, for some reason.
END TYPE

TYPE Vars
  Name AS STRING * 16
  Address AS INTEGER
END TYPE

TYPE SCSStringKey
  Key AS STRING * 16
  Value AS STRING * 64
END TYPE

TYPE SCSNumberKey
  Key AS STRING * 16
  Value AS SINGLE
END TYPE

TYPE SCS
  S(32) AS SCSStringKey
  N(32) AS SCSNumberKey
END TYPE

CONST LogFilename = "A:\LOG.TXT"

DIM SHARED Blanksymbol AS Symbol
DIM SHARED Symbols(100) AS Symbol
DIM SHARED Outp AS Symbol
DIM SHARED Vars(100) AS Vars
DIM SHARED S(100) AS STRING

DIM SHARED logfile AS INTEGER
DIM SHARED LaunchTime AS DOUBLE
LaunchTime = TIMER

DIM SHARED NL AS STRING * 1
NL = CHR$(13)

logfile = FREEFILE
OPEN LogFilename FOR APPEND AS #logfile
PRINT #logfile, ""
PRINT #logfile, "#### stupidc compiler v1 ####"
PRINT #logfile, "(c)2021 all-other-usernames-were-taken"
PRINT #logfile, "launched on: "; DATE$; "@"; TIME$
PRINT #logfile, "with: "; COMMAND$
PRINT #logfile, ""


test

FUNCTION AddLabel$ STATIC
  Labels& = Labels& + 1

  IF Labels& = 0 THEN LogP "ERROR> AddLabel: too many labels! this may create problems with the assembler."

  AddLabel$ = LTRIM$(RTRIM$(STR$(Labels&)))
END FUNCTION

FUNCTION AddSymbol& (Symbol AS Symbol)
  DO
    i& = i& + 1
  LOOP UNTIL (ASC(Symbols(i&).Name) = 32) OR (i& >= UBOUND(Symbols))

  IF i& >= UBOUND(Symbols) THEN LogP "ERROR> AddSymbol: Out of space for symbol '" + Symbol.Name + "'": EXIT FUNCTION

  Symbols(i&) = Symbol
  AddSymbol& = i&
END FUNCTION

SUB Debug.DumpKeys
  SHARED Keys AS SCS

  PRINT "keys.s:"
  FOR i% = 0 TO UBOUND(Keys.S)
    IF ASC(Keys.S(i%).Key) THEN PRINT Keys.S(i%).Key; "="; RTRIM$(Keys.S(i%).Value)
  NEXT


  PRINT : PRINT "keys.n:"

  FOR i% = 0 TO UBOUND(Keys.N)
    IF ASC(Keys.N(i%).Key) THEN PRINT Keys.N(i%).Key; "="; Keys.N(i%).Value
  NEXT
END SUB

SUB Debug.DumpS
  PRINT "S:"
  FOR i% = 0 TO UBOUND(S)
    PRINT LEFT$(S(i%), 10);
  NEXT
END SUB

FUNCTION FILEEXISTS% (Filename$)
  F% = FREEFILE
 
  OPEN Filename$ FOR APPEND AS #F%

  FILEEXISTS% = LOF(F%)
  IF LOF(F%) = 0 THEN KILL Filename$

  CLOSE #F%
END FUNCTION

SUB Func.Or (Args() AS Symbol)
  
END SUB

SUB Func.Pull (Args() AS Symbol)
  S(Outp.Outp) = "FS_PULL"
END SUB

FUNCTION LOADFILE$ (Filename$)
  F% = FREEFILE
  OPEN Filename$ FOR BINARY AS #F%

  DIM c AS STRING * 1
  DO

    GET #F%, , c
    S$ = S$ + c

  LOOP UNTIL EOF(F%)

  LOADFILE$ = S$

  CLOSE #F%
END FUNCTION

SUB LogP (t$)

  CONST Color.Info = 15
  CONST Color.MoreInfo = 7
  CONST Color.Error = 4
  CONST Color.Warning = 5
  CONST Color.FatalError = 12


  IF ASC(t$) = 32 THEN COLOR Color.MoreInfo: GOTO LogP.Print

  b% = INSTR(t$, ">")
  'IF b% = 0 THEN logp "ERROR> LogP: Cannot evaluate type of message '" + t$ + "'": EXIT SUB

  SELECT CASE LEFT$(t$, b% - 1)
    CASE "ERROR"
      COLOR Color.Error

    CASE "FATAL"
      COLOR Color.FatalError

    CASE "INFO"
      COLOR Color.Info

    CASE "WARN"
      COLOR Color.Warning

    CASE ELSE
      COLOR 7
  END SELECT

LogP.Print:
  PRINT t$
  PRINT #logfile, USING "(####.##) &"; TIMER - LaunchTime; t$

END SUB

SUB Mod.Asm (Args() AS Symbol)
  S(Outp.Outp) = S(Args(0).Outp)
END SUB

SUB Mod.Def (Args() AS Symbol)
  DO
    i& = i& + 1
  LOOP UNTIL (ASC(Vars(i&).Name) = 32) OR (i& >= UBOUND(Vars))

  IF i& > UBOUND(Vars) THEN LogP "ERROR> mod.Def: Out of variable space for variable '" + Args(0).Name + "'"

  Vars(i&).Name = Args(0).Name
  Vars(i&).Address = Vars(i& - 1).Address + 1
  S(Outp.Outp) = ""
END SUB

SUB Mod.Halt (Args() AS Symbol)
  S(Outp.Outp) = " JMP *"
END SUB

SUB Mod.If (Args() AS Symbol)
  Label$ = AddLabel
  IF Args(0).type = "?" THEN

      SELECT CASE Args(0).Return
        CASE "+Z"
          S(Outp.Outp) = S(Args(0).Outp) + " BNE " + Label$ + S(Args(1).Outp) + Label$ + ":"

        CASE "-Z"
          S(Outp.Outp) = S(Args(0).Outp) + " BEQ " + Label$ + S(Args(1).Outp) + Label$ + ":"

        CASE "+C"
          S(Outp.Outp) = S(Args(0).Outp) + " BCC " + Label$ + S(Args(1).Outp) + Label$ + ":"

        CASE "-C"
          S(Outp.Outp) = S(Args(0).Outp) + " BCS " + Label$ + S(Args(1).Outp) + Label$ + ":"

      END SELECT

    ELSE
      S(Outp.Outp) = S(Args(0).Outp) + " BNE " + Label$ + S(Args(1).Outp) + Label$ + ":"
  END IF
END SUB

SUB Mod.Include (Args() AS Symbol)
  IF Args(0).type <> CHR$(34) THEN
    LogP "ERROR> mod.Include: Cannot accept type '" + Args(0).type + "'"
    EXIT SUB
  END IF

  LogP "INFO> mod.Include: Loading file '" + S(Args(0).Outp) + "'"
  S(Outp.Outp) = ""
  a$ = LOADFILE$(S(Args(0).Outp))
  Parse a$
  LogP "INFO> mod.Include: Exiting include '" + S(Args(0).Outp) + "'"
END SUB

SUB Mod.Sub (Args() AS Symbol)
  lbl$ = AddLabel
  S(Args(2).Outp) = lbl$
  Args(2).type = "$"
  Args(2).Name = "$" + S(Args(0).Outp)
  sr& = AddSymbol(Args(2))
  S(Outp.Outp) = lbl$ + ":" + S(Args(1).Outp) + " RTS"
END SUB

SUB Mod.System (Args() AS Symbol)
  IF Args(0).type <> CHR$(34) THEN
    LogP "ERROR> mod.System: Cannot use type '" + Args(0).type + "'"
    EXIT SUB
  END IF

  SCS.Load "A:\SYSTEMS\" + S(Args(0).Outp) + ".SCS"
  S(Outp.Outp) = ""
END SUB

SUB Mod.Undef (Args() AS Symbol)
  DO
    i& = i& + 1
  LOOP UNTIL (Vars(i&).Name = Args(0).Name) OR (i& >= UBOUND(Vars))
  
  IF i& >= UBOUND(Vars) THEN LogP "ERROR> Mod.Undef: Variable '" + Args(0).Name + "' is not defined!": EXIT SUB
  IF ASC(Vars(i& - 1).Name) <> 32 THEN LogP "WARN> Mod.Undef: Variable '" + Args(0).Name + "' is buried! undef-ing this variable can cause issues!"

  Vars(i&).Name = ""
END SUB

SUB Parse (Pgm AS STRING)
  DIM Char AS STRING * 1, Args(16) AS Symbol
  SHARED ASMOutput$

  Outp.Outp = S.Reserve%

  FOR i% = 1 TO LEN(Pgm)
    Char = MID$(Pgm, i%, 1)

    SELECT CASE Char
      CASE "(": Level% = Level% + 1
        IF Level% = 1 THEN LastArg% = i% + 1: SymName$ = LEFT$(Pgm, i% - 1)

      CASE ")": Level% = Level% - 1

      CASE "{": Level% = Level% + 1

      CASE "}": Level% = Level% - 1

      CASE ",": IF Level% = 1 THEN GOSUB Parse.RunArg

      CASE ";": IF Level% = 0 THEN GOSUB Parse.RunCmd'end of statement

    END SELECT
    IF Level% = -1 THEN EXIT FOR
  NEXT
  EXIT SUB



Parse.RunCmd:
    GOSUB Parse.RunArg

    Run.Mod SymName$, Args()
    ASMOutput$ = ASMOutput$ + S(Outp.Outp) + NL

    Pgm = MID$(Pgm, i% + 1)

    SymName$ = ""
    CurrentArg% = 0
    i% = 1

  RETURN



Parse.RunArg:
    Run.Sym MID$(Pgm, LastArg%, (i% - LastArg%) - 1)
    Args(CurrentArg%) = Outp

    LastArg% = i% - 1
    CurrentArg% = CurrentArg% + 1

  RETURN
END SUB

FUNCTION Postprocess$ (c$)
  LogP "WARN> Postprocess: Skipping (not supported)"
  Postprocess$ = c$
'  DO
'Postprocess.Next:
'
'    PastBase$ = Base$
'
'    b% = a% + 1
'    a% = INSTR(b%, c$, nl)
'
'    IF a% = 0 THEN EXIT DO
'
'    ln$ = RTRIM$(MID$(c$, b%, a% - b%)) 'Can't LTRIM it 'cause we need the indents
'    LTLn$ = LTRIM$(ln$)
'    i% = INSTR(LTLn$, " ")
'    IF i% THEN Base$ = LEFT$(ln$, i% - 1) ELSE Base$ = LTLn$
'
'    IF LTLn$ = "" THEN
'      GOTO preprocess.next
'
'    elseif Pas
'
'
'
'  LOOP
END FUNCTION

FUNCTION Preprocess$ (Program AS STRING)
  DIM c AS STRING * 1 ', n AS STRING * 1

  FOR i& = 1 TO LEN(Program)
    c = MID$(Program, i&, 1)
    SELECT CASE ASC(c)

      CASE 34
        i2& = INSTR(i& + 1, Program, c)
        IF i2& = 0 THEN
            LogP "ERROR> Preprocess: could not find closing quotation!"
            LogP " " + MID$(Program, i& - 10, 10)
            LogP SPACE$(10) + "^"
          ELSE 'im just gonna ignore that
            o$ = o$ + MID$(Program, i&, i2& - i& + 1)
            i& = i2&
        END IF

      CASE ASC("<")
        i2& = INSTR(i& + 1, Program, ">")
        IF i2& = 0 THEN

          LogP "ERROR> Preprocess: could not find close of comment!"
          LogP " " + MID$(Program, i& - 10, 10)
          LogP SPACE$(10) + "^"

          ELSE i& = i2&
        END IF

      CASE 33 TO 255: o$ = o$ + c

    END SELECT
  NEXT

  Preprocess$ = o$
END FUNCTION

SUB Run.Func (Funcname$)
  SELECT CASE Funcname$

    CASE "pull"
      'Func.Pull args()

  END SELECT
END SUB

SUB Run.Mod (Module$, Args() AS Symbol)
  IF ASC(Module$) = ASC("$") THEN Run.SR MID$(Module$, 2), Args()
  'LogP module$
  SELECT CASE Module$
    CASE "if": Mod.If Args()

    'CASE "while": mod.While args()

    CASE "sub": Mod.Sub Args()

    'CASE "func": mod.Func args()
                
    CASE "def": Mod.Def Args()

    CASE "asm": Mod.Asm Args()

    CASE "halt": Mod.Halt Args()

    CASE "system": Mod.System Args()

    CASE "include", "lib"': Mod.Include args()

    CASE ELSE: LogP "ERROR> Run.Mod: invalid module '" + Module$ + "'"
  END SELECT
END SUB

SUB Run.SR (SubName$, Args() AS Symbol)
  FOR i% = 0 TO UBOUND(Symbols)

    IF Symbols(i%).Name = SubName$ GOTO Run.SR.RunSub
    
  NEXT
  LogP "ERROR> Run.Mod.Sub: Cannot locate subroutine '" + SubName$ + "'"
                        
Run.SR.RunSub:
  'S% = i%
  i% = 0
  DO
    SELECT CASE ASC(Args(i%).type)
      CASE ASC("#")
        S(Outp.Outp) = S(Outp.Outp) + " PUSH #" + LTRIM$(STR$(Args(i%).Value))

      CASE ASC("*")

      CASE ASC("%")
        S(Outp.Outp) = S(Outp.Outp) + " PUSH" + STR$(Args(i%).Value)

      CASE ELSE
        LogP "ERROR> Run.Mod.Sub: Cannot use type '" + Args(i%).type + "' in a sub/function"
        EXIT DO
    END SELECT
    i% = i% + 1
  LOOP

END SUB

SUB Run.Sym (Code$)
  Outp.type = LEFT$(Code$, 1)
  SymName$ = MID$(Code$, 2)

  SELECT CASE Outp.type
    CASE "#"
      IF LEN(SymName$) = 0 THEN LogP "ERROR> Run.Sym: Lonely #. Maybe you should give it some friends.": EXIT SUB

        SELECT CASE ASC(SymName$)
          CASE ASC("$")
            Outp.Value = VAL("&H" + MID$(SymName$, 2))

          CASE ASC("%")
            Outp.Value = VAL("&B" + MID$(SymName$, 2))

          CASE ASC("&")
            Outp.Value = VAL("&O" + MID$(SymName$, 2))

          CASE 34
            Outp.type = CHR$(34)
            S(Outp.Outp) = MID$(SymName$, 2, LEN(SymName$) - 2)
                          
          CASE ELSE
            IF LTRIM$(RTRIM$(STR$(VAL(SymName$)))) = SymName$ THEN
                Outp.Value = VAL(SymName$)
              ELSE
                LogP "ERROR> Run.Sym: '#" + SymName$ + "' when expected decimal number"
            END IF

        END SELECT

      CASE "*"
        'Run.SR.Func symname$

      CASE "?"
        'Run.Bool symname$

      CASE "%"
        FOR i% = 0 TO UBOUND(Vars)
          IF Vars(i%).Name = SymName$ THEN

            S(Outp.Outp) = LTRIM$(RTRIM$(STR$(Vars(i%).Address)))
            Outp.Name = SymName$
            EXIT FOR

          END IF
        NEXT


      CASE "{"
        Parse SymName$

      CASE "&"
        S(Outp.Outp) = SymName$
        Outp.type = "&"

      CASE "."
        Run.Func SymName$

      CASE ELSE
        LogP "ERROR> Run.Sym: cannot determine type of symbol '" + Outp.type + SymName$ + "'"

    END SELECT
END SUB

SUB S.Free (h AS INTEGER)
  IF S(h) = "" THEN LogP "WARN> S.Free: 'S(" + STR$(h) + ")' is not initialized"
  S(h) = CHR$(255)
END SUB

SUB S.Init
  FOR i% = 0 TO UBOUND(S)
    S(i%) = CHR$(255)
  NEXT
END SUB

FUNCTION S.Reserve%
  FOR i% = 0 TO UBOUND(S)

    IF S(i%) = "" GOTO S.Reserve.Next

    IF ASC(S(i%)) = 255 THEN

      S.Reserve% = i%
      S(i%) = ""
      EXIT FUNCTION

    END IF

S.Reserve.Next:
  NEXT

  LogP "ERROR> S.Reserve: s() is full, cannot reserve new string space!"
  S.Reserve% = 0
END FUNCTION

FUNCTION SCS.GetNumKey! (Key$)
  SHARED Keys AS SCS

  FOR i% = 0 TO UBOUND(Keys.N)
    IF RTRIM$(Keys.N(i%).Key) = Key$ THEN

      SCS.GetNumKey! = Keys.N(i%).Value
      EXIT FOR

    END IF
  NEXT
  IF i% = UBOUND(Keys.N) THEN LogP "ERROR> SCS.GetNumKey: Key '" + Key$ + "' not found!"
END FUNCTION

FUNCTION SCS.GetStrKey$ (Key$)
  SHARED Keys AS SCS

  FOR i% = 0 TO UBOUND(Keys.S)
    IF RTRIM$(Keys.S(i%).Key) = Key$ THEN

      SCS.GetStrKey$ = Keys.S(i%).Value
      EXIT FOR

    END IF
  NEXT
  IF i% = UBOUND(Keys.S) THEN LogP "ERROR> SCS.GetStrKey$: Key '" + Key$ + "' not found!"
END FUNCTION

SUB SCS.Load (Filename$)
  SHARED Keys AS SCS



  ERASE Keys.S, Keys.N

  F% = FREEFILE
  LogP "INFO> SCS.Load: Loading SCS file '" + Filename$ + "'"
  IF FILEEXISTS(Filename$) = 0 THEN LogP "ERROR> SCS.Load: File not found!": EXIT SUB
  OPEN Filename$ FOR INPUT AS #F%

  DO
    LINE INPUT #F%, ln$
    ln$ = LTRIM$(RTRIM$(ln$))

    i% = INSTR(ln$, " ")
    IF i% = 0 THEN GOTO SCS.Load.Next

    Key$ = LTRIM$(RTRIM$(MID$(ln$, 2, i% - 2)))
    Val$ = LTRIM$(RTRIM$(MID$(ln$, i% + 1)))
                
    IF UCASE$(Val$) = "TRUE" THEN Val$ = "-1"
    IF UCASE$(Val$) = "FALSE" THEN Val$ = "0"

    SELECT CASE ASC(ln$)
      CASE ASC("#")
        'Ignore it

      CASE ASC("=")
        FOR i% = 0 TO UBOUND(Keys.N)
          IF ASC(Keys.N(i%).Key) = 0 THEN

            Keys.N(i%).Key = UCASE$(Key$)
            Keys.N(i%).Value = VAL(Val$)
            EXIT FOR

          END IF
        NEXT
        IF i% = UBOUND(Keys.N) THEN LogP "ERROR> SCS.Load: Out of space for number key '" + Key$ + "'!"

      CASE ASC("$")
        FOR i% = 0 TO UBOUND(Keys.S)
          IF ASC(Keys.S(i%).Key) = 0 THEN

            Keys.S(i%).Key = UCASE$(Key$)
            Keys.S(i%).Value = Val$
            EXIT FOR
            
          END IF
        NEXT
        IF i% = UBOUND(Keys.S) THEN LogP "ERROR> SCS.Load: Out of space for string key '" + Key$ + "'!"

      CASE ASC("{")
        DO

          LINE INPUT #F%, ln$
          ln$ = LTRIM$(RTRIM$(ln$))
          IF ln$ = "}" THEN EXIT DO
          Val$ = Val$ + ln$ + CHR$(10) + CHR$(13)

        LOOP UNTIL EOF(F%)
        IF EOF(F%) THEN LogP "WARN> SCS.Load: Unexpected EOF while reading multi-line key '" + Key$ + "'"

        FOR i% = 0 TO UBOUND(Keys.S)
          IF ASC(Keys.S(i%).Key) = 0 THEN

            Keys.S(i%).Key = UCASE$(Key$)
            Keys.S(i%).Value = Val$
            EXIT FOR

          END IF
        NEXT
        IF i% = UBOUND(Keys.S) THEN LogP "ERROR> SCS.Load: Out of space for multi-line key '" + Key$ + "'!"
                                                                                                                                                                                         
      CASE ELSE
        LogP "ERROR> SCS.Load: Unknown key type '" + LEFT$(ln$, 1) + "'"

    END SELECT
SCS.Load.Next:
  LOOP UNTIL EOF(F%)
END SUB

SUB test

  CONST file = "A:\SAMPLES\GAME.SC"
  CLS
  LogP "INFO> Compiling file '" + file + "'"

  S.Init

  LogP "INFO> Loading file"
  a$ = LOADFILE$(file)

  LogP "INFO> Entering stage 1"
  CHDIR "A:\"
  b$ = Preprocess$(a$)

  LogP "INFO> Entering stage 2"
  Parse b$

  LogP "INFO> Entering stage 3"
  a$ = Postprocess$(b$)

  LogP "INFO> Compilation finished."
  PRINT ASMOutput$

END SUB

