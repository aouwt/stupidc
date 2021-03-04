DECLARE FUNCTION Postprocess$ (C$)
DECLARE SUB Run.Sym (Code$)
DECLARE SUB S.Init ()
DECLARE FUNCTION S.Reserve% ()
DECLARE FUNCTION ScreenWidth% ()
DECLARE SUB PrintHelp ()
DECLARE SUB Run.Sub (SubName$, Args() AS ANY)
DECLARE SUB S.Free (h AS INTEGER)
DECLARE SUB GetPgmArgs (NumArgs AS INTEGER, Args$())

'$INCLUDE: 'SCMODS.BI'
'$INCLUDE: 'COMMON.BI'

ON ERROR GOTO ErrorHandler

DIM SHARED Symbols(100) AS symbol
DIM SHARED Vars(100) AS Vars
DIM SHARED S(100) AS STRING

DIM SHARED LogFile AS STRING
DIM SHARED OutputFile AS STRING
DIM SHARED InputFile AS STRING

DIM SHARED File.Log AS INTEGER
DIM SHARED File.Out AS INTEGER
DIM SHARED File.In AS INTEGER

DIM SHARED ErrorCount AS INTEGER
DIM SHARED WarnCount AS INTEGER

DIM Cmd.Args(10) AS STRING
DIM Cmd.ArgCount AS INTEGER

DIM SHARED ScrW AS INTEGER
DIM SHARED LaunchTime AS DOUBLE

'$INCLUDE: 'DEFAULTS.BI'

CLS

'IF COMMAND$ = "" THEN LogP "FATAL> No input file specified!": PrintHelp

S.Init
Outp.Outp = S.Reserve

CALL GetPgmArgs(Cmd.ArgCount, Cmd.Args())

FOR i% = 0 TO Cmd.ArgCount

  SELECT CASE Cmd.Args(i%)

    CASE "-o"
      i% = i% + 1
      OutputFile = Cmd.Args(i%)

    CASE "-h"
      PrintHelp

    CASE "-l"
      i% = i% + 1
      LogFile = Cmd.Args(i%)

    CASE "": LogP "WARN> SETUP.BI: Blank element in Cmd.Args()!"

    CASE ELSE
      'i% = i% + 1
      IF FILEEXISTS(Cmd.Args(i%)) = 0 THEN
        LogP "FATAL> File '" + Cmd.Args(i%) + "' does not exist!"
        SYSTEM

       ELSE InputFile = Cmd.Args(i%)
      END IF

  END SELECT

NEXT

File.Log = FREEFILE: OPEN LogFile FOR OUTPUT AS #File.Log
'File.In = FREEFILE: OPEN InputFile FOR BINARY AS #File.In
File.Out = FREEFILE: OPEN OutputFile FOR OUTPUT AS #File.Out

