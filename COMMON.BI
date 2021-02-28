TYPE Symbol
  Name AS STRING * 16
  Type AS STRING * 1
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


DECLARE FUNCTION SCS.GetNumKey! (Key$)
DECLARE FUNCTION SCS.GetStrKey$ (Key$)
DECLARE SUB SCS.Load (Filename$)
DECLARE SUB Debug.DumpKeys ()
DECLARE FUNCTION AddLabel$ ()
DECLARE FUNCTION AddSymbol& (Symbol AS Symbol)
DECLARE SUB Debug.DumpS ()
DECLARE FUNCTION FILEEXISTS% (Filename$)
DECLARE FUNCTION LOADFILE$ (Filename$)
DECLARE SUB LogP (t$)
DECLARE FUNCTION Preprocess$ (Program AS STRING)
DECLARE SUB Parse (Pgm AS STRING)

COMMON SHARED BlankSymbol AS Symbol
COMMON SHARED Symbols() AS Symbol
COMMON SHARED Outp AS Symbol
COMMON SHARED Vars() AS Vars
COMMON SHARED S() AS STRING
COMMON SHARED ASMOutput AS STRING
COMMON Keys AS SCS

COMMON SHARED nl AS STRING * 2

DIM S(100) AS STRING
DIM Vars(100) AS Vars
DIM Symbols(100) AS Symbol

