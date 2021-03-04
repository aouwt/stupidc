'$INCLUDE: 'SETUP.BI'



Outp.Outp = S.Reserve%


LogP "INFO> Compiling file '" + InputFile + "'"

LogP "INFO> Loading file"
a$ = LOADFILE$(InputFile)

LogP "INFO> Entering stage 1"
a$ = Preprocess$(a$)

LogP "INFO> Entering stage 2"
Parse a$

LogP "INFO> Finalizing"
ASMOutput = SCS.GetStrKey("asmhead") + ASMOutput + SCS.GetStrKey("asmfoot")


IF SGN(ErrorCount) = -1 THEN
    LogP "ERROR> Compilation failed with" + STR$(ErrorCount * -1) + " errors and" + STR$(WarnCount) + " warnings."
  ELSE
    LogP "SUCCESS> Compilation finished with" + STR$(ErrorCount) + " errors and" + STR$(WarnCount) + " warnings."
END IF


LogP "INFO> Saving file"
PRINT #File.Out, ASMOutput;
'PRINT ASMOutput
SYSTEM


ErrorHandler:
  LogP "INTERNAL> Error #" + LTRIM$(STR$(ERR)) + " at line" + STR$(ERL) + ": " + ERROR$
RESUME NEXT

FUNCTION AddLabel$ ()
  Labels& = Labels& + 1

  IF Labels& = 0 THEN LogP "ERROR> AddLabel: too many labels! this may create problems with the assembler."

  AddLabel$ = LTRIM$(RTRIM$(STR$(Labels&)))
END FUNCTION

FUNCTION AddSymbol& (symbol AS symbol)
  DO
    i& = i& + 1
  LOOP UNTIL (ASC(Symbols(i&).Name) = 32) OR (i& >= UBOUND(Symbols))

  IF i& >= UBOUND(Symbols) THEN LogP "ERROR> AddSymbol: Out of space for symbol '" + symbol.Name + "'": EXIT FUNCTION

  Symbols(i&) = symbol
  AddSymbol& = i&
END FUNCTION

SUB Debug.DumpS ()
  PRINT "S:"
  FOR i% = 0 TO UBOUND(S)
    PRINT LEFT$(S(i%), 10);
  NEXT
END SUB

FUNCTION FILEEXISTS% (Filename$)

  F% = FREEFILE

  ON LOCAL ERROR RESUME NEXT
  OPEN Filename$ FOR BINARY AS #F%
  ON LOCAL ERROR GOTO 0

  IF F% = FREEFILE THEN FILEEXISTS% = 0 ELSE FILEEXISTS% = -1
  CLOSE #F%

END FUNCTION

STATIC SUB GetPgmArgs (ArgCount AS INTEGER, Args$())

  DO
    i% = i% + 1
    SELECT CASE MID$(COMMAND$, i%, 1)

      'CASE "-"
      '  Args$(NextArg%) = MID$(COMMAND$, i%, 2)
      '  i% = i% + 1

      CASE CHR$(34)
        a% = INSTR(i% + 1, COMMAND$, CHR$(34))
        Args$(NextArg%) = MID$(COMMAND$, i% + 1, a% - i% - 1)
        i% = a%

      CASE " "
        IF Args$(NextArg%) <> "" THEN NextArg% = NextArg% + 1

      CASE "": EXIT DO

      CASE ELSE
        Args$(NextArg%) = Args$(NextArg%) + MID$(COMMAND$, i%, 1)

    END SELECT
  LOOP
  ArgCount = NextArg%

END SUB

FUNCTION LOADFILE$ (Filename$)
  IF FILEEXISTS%(Filename$) = 0 THEN LogP "ERROR> LOADFILE: File does not exist!": EXIT FUNCTION
  F% = FREEFILE
  OPEN Filename$ FOR BINARY AS #F%

  DIM C AS STRING * 1
  DO

    GET #F%, , C
    S$ = S$ + C

  LOOP UNTIL EOF(F%)

  LOADFILE$ = S$

  CLOSE #F%
END FUNCTION

SUB LogP (t$)

  CONST Color.Info = 15
  CONST Color.More = 7
  CONST Color.Error = 4
  CONST Color.Warning = 5
  CONST Color.FatalError = 12
  CONST Color.InternalError = 12
  CONST Color.Success = 2
  CONST Color.Debug = 9

  ASMOutput = ASMOutput + ";;" + t$ + NL

  IF ASC(t$) = 32 THEN

    COLOR Color.More
    M$ = MID$(t$, 2)
    GOTO LogP.Print

  END IF

  b% = INSTR(t$, ">")
  C$ = LEFT$(t$, b% - 1)
  M$ = MID$(t$, b%)
  'PRINT

  SELECT CASE C$
    CASE "ERROR"
      COLOR Color.Error
      IF SGN(ErrorCount) = -1 THEN ErrorCount = ErrorCount - 1 ELSE ErrorCount = ErrorCount + 1

    CASE "FATAL"
      COLOR Color.FatalError
      IF SGN(ErrorCount) = -1 THEN ErrorCount = ErrorCount - 1 ELSE ErrorCount = (ErrorCount + 1) * -1

    CASE "INFO"
      COLOR Color.Info

    CASE "WARN"
      COLOR Color.Warning
      WarnCount = WarnCount + 1

    CASE "SUCCESS"
      COLOR Color.Success

    CASE "INTERNAL"
      COLOR Color.InternalError
      IF SGN(ErrorCount) = -1 THEN ErrorCount = ErrorCount - 1 ELSE ErrorCount = ErrorCount + 1

    CASE "DEBUG"
      COLOR Color.Debug

    CASE ELSE
      COLOR Color.More

  END SELECT

LogP.Print:

  IF File.Log = 0 THEN
    File.Log = FREEFILE
    OPEN LogFile FOR APPEND AS #File.Log

    ' "WARN> LogP: File.Log is not opened! Opening temporarily."

    PRINT #File.Log, USING "(####.##) &"; TIMER - LaunchTime; t$

    CLOSE #File.Log
    File.Log = 0

   ELSE
    PRINT #File.Log, USING "(####.##) &"; TIMER - LaunchTime; t$

  END IF


  PRINT C$;

  COLOR Color.More

  IF LEN(t$) > (ScrW) THEN

    x% = ScrW - POS(0)
    PRINT LEFT$(M$, x% + 1)
    PRINT MID$(M$, x% + 2, ScrW)

  ELSE PRINT M$
  END IF

END SUB

SUB LogWhere (Text AS STRING, Where AS INTEGER)
  'ON LOCAL ERROR RESUME NEXT

  IF (Where - 16) < 0 THEN

      LogP " " + LEFT$(Text, 30)
      LogP " " + STRING$(Where - 1, "~") + "^"
      'LogP " "


    ELSE

      LogP " " + MID$(Text, Where - 16, 30)
      LogP " " + STRING$(15, "~") + "^"
      'LogP " "

  END IF

  'ON LOCAL ERROR GOTO 0
END SUB

SUB Parse (Pgm AS STRING)
  DIM Char AS STRING * 1, Args(16) AS symbol

  FOR i% = 1 TO LEN(Pgm)
    Char = MID$(Pgm, i%, 1)

    SELECT CASE Char
      CASE "(": Level% = Level% + 1
        IF Level% = 1 THEN LastArg% = i% + 1: SymName$ = LEFT$(Pgm, i% - 1)

      CASE ")": Level% = Level% - 1

      CASE "{": Level% = Level% + 1

      CASE "}": Level% = Level% - 1

      CASE ","
        IF Level% = 1 THEN GOSUB Parse.RunArg

      CASE ";": IF Level% = 0 THEN GOSUB Parse.RunCmd'end of statement

    END SELECT
    IF Level% = -1 THEN EXIT FOR
  NEXT
  EXIT SUB



Parse.RunCmd:
    GOSUB Parse.RunArg

    LogP "DEBUG> Parse: Running"
    LogWhere Pgm, i%

    Outp.Outp = S.Reserve

    IF ASC(SymName$) = ASC("$") THEN
        Run.Sub MID$(SymName$, 2), Args()
      ELSE
        ModRun.R SymName$, Args()
    END IF

    ASMOutput = ASMOutput + S(Outp.Outp) + NL

    Pgm = MID$(Pgm, i% + 1)

    FOR i% = 0 TO UBOUND(Args)
      S.Free Args(i%).Outp
      Args(i%) = BlankSymbol
    NEXT
    S.Free Outp.Outp


    SymName$ = ""
    CurrentArg% = 0
    LastArg% = 0
    i% = 1

  RETURN



Parse.RunArg:
    S.Free Outp.Outp
    Outp.Outp = S.Reserve
    Run.Sym MID$(Pgm, LastArg%, (i% - LastArg%) - 1)
    Args(CurrentArg%) = Outp

    'S.Free Outp.Outp

    LastArg% = i% + 1' - 1
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

  FOR i% = 1 TO LEN(Program)
    C = MID$(Program, i%, 1)
    SELECT CASE ASC(C)

      CASE 34
        i2% = INSTR(i% + 1, Program, C)
        IF i2% = 0 THEN
            LogP "ERROR> Preprocess: could not find closing quotation!"
            LogWhere Program, i%

          ELSE 'im just gonna ignore that
            o$ = o$ + MID$(Program, i%, i2% - i% + 1)
            i% = i2%
        END IF

      CASE ASC("<")
        i2% = INSTR(i% + 1, Program, ">")
        IF i2% = 0 THEN

          LogP "ERROR> Preprocess: could not find close of comment!"
          LogWhere Program, i%

        ELSE i% = i2%
        END IF

      CASE 33 TO 255: o$ = o$ + C

    END SELECT
  NEXT

  Preprocess$ = o$
END FUNCTION

SUB PrintHelp ()
  PRINT ""
  PRINT "stupidc compiler"
  PRINT "(c)2021 all-other-usernames-were-taken"
  PRINT "https://github.com/all-other-usernames-were-taken/stupidc"
  PRINT "---------------------------------------"
  PRINT ""
  PRINT "Usage: STUPIDC <input file> <options>"
  PRINT ""
  PRINT "Options:"
  PRINT , "-o <file>", "Assembly source output file"
  'PRINT , "-s <file>", "Force usage of <file> SCS file"
  'PRINT , "-q", "Turn off error reporting"
  'PRINT , "-i <file>", "Include <file> at the beginning of the program"
  'PRINT , "-I <file>", "Include <file> at the end of the program"
  PRINT , "-h", "Prints this screen then exits"
  PRINT , "-l <file>", "Use <file> as the logfile"
 END 0
END SUB

SUB Run.Sub (SubName$, Args() AS symbol)
  FOR i% = 0 TO UBOUND(Symbols)

   IF Symbols(i%).Name = SubName$ GOTO Run.SR.RunSub
    
  NEXT
  LogP "ERROR> Run.Sub: Cannot locate subroutine '" + SubName$ + "'"
                        
Run.SR.RunSub:
  'S% = i%
  i% = 0
  DO
    SELECT CASE ASC(Args(i%).Type)
      CASE ASC("#")
        S(Outp.Outp) = NL + S(Outp.Outp) + " LDA #" + LTRIM$(STR$(Args(i%).Value)) + NL + " PUSH"

      CASE ASC("*")

      CASE ASC("%")
        S(Outp.Outp) = NL + S(Outp.Outp) + " LDA" + STR$(Args(i%).Value) + NL + " PUSH"

      CASE 32: EXIT DO
      CASE ELSE
        LogP "ERROR> Run.Sub: Cannot use type '" + Args(i%).Type + "' in a sub/function"
        EXIT DO

    END SELECT
    i% = i% + 1
  LOOP

END SUB

SUB Run.Sym (Code$)
  Outp.Type = LEFT$(Code$, 1)
  SymName$ = MID$(Code$, 2)

  ASMOutput = ASMOutput + ";Run.Sym " + Code$ + NL

  SELECT CASE Outp.Type
    CASE "#"
      IF LEN(SymName$) = 0 THEN
      
        LogP "ERROR> Run.Sym: Lonely #. Maybe you should give it some friends."
        LogWhere Code$, 2
        EXIT SUB
        
      END IF

      SELECT CASE ASC(SymName$)
        CASE ASC("$"): Outp.Value = VAL("&H" + MID$(SymName$, 2))
        CASE ASC("%"): Outp.Value = VAL("&B" + MID$(SymName$, 2))
        CASE ASC("&"): Outp.Value = VAL("&O" + MID$(SymName$, 2))

        CASE 34
          Outp.Type = CHR$(34)
          S(Outp.Outp) = MID$(SymName$, 2, LEN(SymName$) - 2)
                          
        CASE ELSE
          IF LTRIM$(STR$(VAL(SymName$))) = SymName$ THEN
              Outp.Value = VAL(SymName$)
            ELSE
              LogP "ERROR> Run.Sym: Expected decimal number!"
              LogWhere Code$, 2
          END IF

        END SELECT


      CASE "*"
        'Run.Func SymName$

      CASE "?"
        'Run.Bool symname$

      CASE "%"
        FOR i% = 0 TO UBOUND(Vars)
          IF Vars(i%).Name = SymName$ THEN

            S(Outp.Outp) = LTRIM$(STR$(Vars(i%).Address))
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
        LogP "ERROR> Run.Sym: cannot determine type of symbol!"
        LogWhere Code$, 1

    END SELECT
END SUB

SUB S.Free (h AS INTEGER)
  IF S(h) = "" THEN LogP "WARN> S.Free: 'S(" + LTRIM$(STR$(h)) + ")' is not initialized"
  S(h) = CHR$(255)
END SUB

SUB S.Init ()
  FOR i% = 0 TO UBOUND(S)
    S(i%) = CHR$(255)
  NEXT
END SUB

FUNCTION S.Reserve% ()
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

FUNCTION ScreenWidth% ()
  x% = POS(0)
  y% = CSRLIN

  LOCATE 1, 1
  DO

    i% = i% + 1
    PRINT CHR$(SCREEN(CSRLIN, POS(0)));

  LOOP UNTIL CSRLIN <> 1
  ScreenWidth% = i%

  LOCATE x%, y%
END FUNCTION

