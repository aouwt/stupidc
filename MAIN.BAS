DECLARE SUB S.Free (h AS INTEGER)
DECLARE SUB GetPgmArgs (NumArgs!, Args$())
DECLARE FUNCTION Postprocess$ (C$)
DECLARE SUB Run.Sym (Code$)
DECLARE SUB S.Init ()
DECLARE FUNCTION S.Reserve% ()
DECLARE FUNCTION ScreenWidth% ()

'$INCLUDE: 'A:\SCMODS.BI'
'$INCLUDE: 'A:\COMMON.BI'

nl = CHR$(10) + CHR$(13)
CONST LogFilename = "A:\LOG.TXT"

DIM SHARED ErrorCount AS INTEGER
DIM SHARED WarnCount AS INTEGER

DIM SHARED ScrW AS INTEGER
ScrW = ScreenWidth

DIM SHARED logfile AS INTEGER
DIM SHARED LaunchTime AS DOUBLE
LaunchTime = TIMER


logfile = FREEFILE
OPEN LogFilename FOR OUTPUT AS #logfile
PRINT #logfile, ""
PRINT #logfile, "#### stupidc compiler v1 ####"
PRINT #logfile, "(c)2021 all-other-usernames-were-taken"
PRINT #logfile, "launched on: "; DATE$; "@"; TIME$
PRINT #logfile, "with: "; COMMAND$
PRINT #logfile, ""

S.Init
DIM Cmd.Args(10) AS STRING
CALL GetPgmArgs(Cmd.ArgCount, Cmd.Args())
Outp.Outp = S.Reserve%

file$ = COMMAND$
CLS
LogP "INFO> Compiling file '" + file$ + "'"

LogP "INFO> Loading file"
a$ = LOADFILE$(file$)

LogP "INFO> Entering stage 1"
CHDIR "A:\"
a$ = Preprocess$(a$)

LogP "INFO> Entering stage 2"
Parse a$

'LogP "INFO> Entering stage 3"
'ASMOutput = Postprocess$(ASMOutput)

IF SGN(ErrorCount) = -1 THEN
    LogP "ERROR> Compilation failed with" + STR$(ErrorCount * -1) + " errors and" + STR$(WarnCount) + " warnings."
  ELSE
    LogP "SUCCESS> Compilation finished with" + STR$(ErrorCount) + " errors and" + STR$(WarnCount) + " warnings."
END IF

f% = FREEFILE
OPEN "A:\OUTPUT.ASM" FOR OUTPUT AS #f%
PRINT #f%, ASMOutput
CLOSE f%
SLEEP

'SHELL "C:\FREEDOS\EDIT A:\OUTPUT.ASM A:\LOG.TXT"

FUNCTION AddLabel$ ()
  Labels& = Labels& + 1

  IF Labels& = 0 THEN LogP "ERROR> AddLabel: too many labels! this may create problems with the assembler."

  AddLabel$ = LTRIM$(RTRIM$(STR$(Labels&)))
END FUNCTION

FUNCTION AddSymbol& (Symbol AS Symbol)
  DO
    I& = I& + 1
  LOOP UNTIL (ASC(Symbols(I&).Name) = 32) OR (I& >= UBOUND(Symbols))

  IF I& >= UBOUND(Symbols) THEN LogP "ERROR> AddSymbol: Out of space for symbol '" + Symbol.Name + "'": EXIT FUNCTION

  Symbols(I&) = Symbol
  AddSymbol& = I&
END FUNCTION

SUB Debug.DumpS ()
  PRINT "S:"
  FOR I% = 0 TO UBOUND(S)
    PRINT LEFT$(S(I%), 10);
  NEXT
END SUB

FUNCTION FILEEXISTS% (Filename$)
  f% = FREEFILE
  OPEN Filename$ FOR APPEND AS #f%

  FILEEXISTS% = LOF(f%)
  IF LOF(f%) = 0 THEN KILL Filename$

  CLOSE #f%
END FUNCTION

SUB Get.Sub (SubName$, Args() AS Symbol)
  FOR I% = 0 TO UBOUND(Symbols)

   IF Symbols(I%).Name = SubName$ GOTO Run.SR.RunSub
    
  NEXT
  LogP "ERROR> Get.Sub: Cannot locate subroutine '" + SubName$ + "'"
                        
Run.SR.RunSub:
  'S% = i%
  I% = 0
  DO
    SELECT CASE ASC(Args(I%).Type)
      CASE ASC("#")
        S(Outp.Outp) = nl + S(Outp.Outp) + " PUSH #" + LTRIM$(STR$(Args(I%).Value))

      CASE ASC("*")

      CASE ASC("%")
        S(Outp.Outp) = nl + S(Outp.Outp) + " PUSH" + STR$(Args(I%).Value)

      CASE ELSE
        LogP "ERROR> Get.Sub: Cannot use type '" + Args(I%).Type + "' in a sub/function"
        EXIT DO

    END SELECT
    I% = I% + 1
  LOOP

END SUB

STATIC SUB GetPgmArgs (NumArgs, Args$()) ', MaxArgs)

     'The following is a sample command line and output for a stand-alone
     ' executable file (assumes program name is ARG.EXE):
     '
     ' arg one  two   three    four     five      six
     
     ' Use SUB procedure to get command line and split into arguments.
     ' Parameters:  NumArgs : Number of command-line arguments found
     '              Args$() : Array in which to return arguments
     '              MaxArgs : Maximum number of arguments array can return

     CONST TRUE = -1, FALSE = 0
 
     NumArgs = 0: In = FALSE
     MaxArgs = UBOUND(Args$)
     ' Get the command line using the COMMAND$ function
     Cl$ = COMMAND$
     L = LEN(Cl$)
     ' Go through the command line a character at a time
     FOR I = 1 TO L
          C$ = MID$(Cl$, I, 1)
          ' Test for character being a blank or a tab
          IF (C$ <> " " AND C$ <> CHR$(9)) THEN
          ' Neither blank nor tab; test if you're already inside
          ' an argument
               IF NOT In THEN
               ' You've found the start of a new argument
                    ' Test for too many arguments
                      IF NumArgs = MaxArgs THEN EXIT FOR
                      NumArgs = NumArgs + 1
                      In = TRUE
               END IF
               ' Add the character to the current argument
               Args$(NumArgs) = Args$(NumArgs) + C$
          ELSE
          ' Found a blank or a tab.
               ' Set "Not in an argument" flag to FALSE
               In = FALSE
          END IF
     NEXT I
 
END SUB

FUNCTION LOADFILE$ (Filename$)
  f% = FREEFILE
  OPEN Filename$ FOR BINARY AS #f%

  DIM C AS STRING * 1
  DO

    GET #f%, , C
    S$ = S$ + C

  LOOP UNTIL EOF(f%)

  LOADFILE$ = S$

  CLOSE #f%
END FUNCTION

SUB LogP (t$)

  CONST Color.Info = 15
  CONST Color.More = 7
  CONST Color.Error = 4
  CONST Color.Warning = 5
  CONST Color.FatalError = 12
  CONST Color.Success = 2

  ASMOutput = ASMOutput + ";;" + t$ + nl

  IF ASC(t$) = 32 THEN COLOR Color.More: GOTO LogP.Print

  b% = INSTR(t$, ">")
  C$ = LEFT$(t$, b% - 1)
  m$ = MID$(t$, b%)

  SELECT CASE C$
    CASE "ERROR"
      COLOR Color.Error
      ErrorCount = ErrorCount + 1

    CASE "FATAL"
      COLOR Color.FatalError
      ErrorCount = ErrorCount * -1

    CASE "INFO"
      COLOR Color.Info

    CASE "WARN"
      COLOR Color.Warning
      WarnCount = WarnCount + 1

    CASE "SUCCESS"
      COLOR Color.Success

    CASE ELSE
      COLOR Color.More

  END SELECT

LogP.Print:
  PRINT C$;

  COLOR Color.More

  IF LEN(t$) > (ScrW) THEN

    x% = ScrW - POS(0)
    PRINT LEFT$(m$, x% + 1)
    PRINT SPACE$(3) + MID$(m$, x% + 2, ScrW - 6) + "..."

  ELSE PRINT m$
  END IF

  PRINT #logfile, USING "(####.##) &"; TIMER - LaunchTime; t$

END SUB

SUB Parse (Pgm AS STRING)
  DIM Char AS STRING * 1, Args(16) AS Symbol

  FOR I% = 1 TO LEN(Pgm)
    Char = MID$(Pgm, I%, 1)

    SELECT CASE Char
      CASE "(": Level% = Level% + 1
        IF Level% = 1 THEN LastArg% = I% + 1: SymName$ = LEFT$(Pgm, I% - 1)

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

    ModRun.R SymName$, Args()
    ASMOutput = ASMOutput + S(Outp.Outp) + nl

    Pgm = MID$(Pgm, I% + 1)

    SymName$ = ""
    CurrentArg% = 0
    I% = 1

  RETURN



Parse.RunArg:
    S.Free Outp.Outp
    Outp.Outp = S.Reserve
    Run.Sym MID$(Pgm, LastArg%, (I% - LastArg%) - 1)
    Args(CurrentArg%) = Outp
    'S(Outp.Outp) = ""

    LastArg% = I% - 1
    CurrentArg% = CurrentArg% + 1

  RETURN
END SUB

FUNCTION Postprocess$ (C$)
  LogP "WARN> Postprocess: Skipping (not supported)"
  Postprocess$ = C$
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
  DIM C AS STRING * 1 ', n AS STRING * 1

  FOR I& = 1 TO LEN(Program)
    C = MID$(Program, I&, 1)
    SELECT CASE ASC(C)

      CASE 34
        i2& = INSTR(I& + 1, Program, C)
        IF i2& = 0 THEN
            LogP "ERROR> Preprocess: could not find closing quotation!"
            LogP " " + MID$(Program, I& - 10, 10)
            LogP SPACE$(10) + "^"
          ELSE 'im just gonna ignore that
            o$ = o$ + MID$(Program, I&, i2& - I& + 1)
            I& = i2&
        END IF

      CASE ASC("<")
        i2& = INSTR(I& + 1, Program, ">")
        IF i2& = 0 THEN

          LogP "ERROR> Preprocess: could not find close of comment!"
          LogP " " + MID$(Program, I& - 10, 10)
          LogP SPACE$(10) + "^"

          ELSE I& = i2&
        END IF

      CASE 33 TO 255: o$ = o$ + C

    END SELECT
  NEXT

  Preprocess$ = o$
END FUNCTION

SUB Run.Sym (Code$)
  Outp.Type = LEFT$(Code$, 1)
  SymName$ = MID$(Code$, 2)

  ASMOutput = ASMOutput + ";Run.Sym " + Code$ + nl

  SELECT CASE Outp.Type
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
            Outp.Type = CHR$(34)
            S(Outp.Outp) = MID$(SymName$, 2, LEN(SymName$) - 2)
                          
          CASE ELSE
            IF LTRIM$(STR$(VAL(SymName$))) = SymName$ THEN
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
        FOR I% = 0 TO UBOUND(Vars)
          IF Vars(I%).Name = SymName$ THEN

            S(Outp.Outp) = LTRIM$(STR$(Vars(I%).Address))
            Outp.Name = SymName$
            EXIT FOR

          END IF
        NEXT



      CASE "{"
        Parse SymName$

      CASE "&"
        S(Outp.Outp) = SymName$

      CASE "."
        'ModRun.F SymName$

      CASE ELSE
        LogP "ERROR> Run.Sym: cannot determine type of symbol '" + Outp.Type + SymName$ + "'"

    END SELECT
END SUB

SUB S.Free (h AS INTEGER)
  IF S(h) = "" THEN LogP "WARN> S.Free: 'S(" + STR$(h) + ")' is not initialized"
  S(h) = CHR$(255)
END SUB

SUB S.Init ()
  FOR I% = 0 TO UBOUND(S)
    S(I%) = CHR$(255)
  NEXT
END SUB

FUNCTION S.Reserve% ()
  FOR I% = 0 TO UBOUND(S)

    IF S(I%) = "" GOTO S.Reserve.Next

    IF ASC(S(I%)) = 255 THEN

      S.Reserve% = I%
      S(I%) = ""
      EXIT FUNCTION

    END IF

S.Reserve.Next:
  NEXT

  LogP "ERROR> S.Reserve: s() is full, cannot reserve new string space!"
  S.Reserve% = 0
END FUNCTION

FUNCTION ScreenWidth% ()
  x% = POS(0)
  y% = CSRLIN

  LOCATE 1, 1
  DO

    I% = I% + 1
    PRINT CHR$(SCREEN(CSRLIN, POS(0)));

  LOOP UNTIL CSRLIN <> 1
  ScreenWidth% = I%

  LOCATE x%, y%
END FUNCTION

