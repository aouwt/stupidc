DECLARE SUB run.mod.sub (subname$, args() AS ANY)
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
  outp AS INTEGER 'Location in the out() array. QB can't use variable-length strings in UDTs, for some reason.
END TYPE

TYPE vars
  name AS STRING * 16
  address AS INTEGER
END TYPE

TYPE scsStringKey
  key AS STRING * 16
  value AS STRING * 64
END TYPE

TYPE scsNumberKey
  key AS STRING * 16
  value AS SINGLE
END TYPE

TYPE scs
  s(32) AS scsStringKey
  n(32) AS scsNumberKey
END TYPE

