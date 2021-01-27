DECLARE SUB mod.halt (args() AS ANY)
DECLARE FUNCTION postprocess$ (c$)
DECLARE FUNCTION preprocess$ (program AS STRING)
DECLARE SUB parse (line$)
DECLARE SUB mod.asm (args() AS ANY)
DECLARE FUNCTION addsymbol& (symbol AS ANY)
DECLARE FUNCTION addlabel$ ()
DECLARE SUB mod.def (args() AS ANY)
DECLARE SUB mod.if (args() AS ANY)
DECLARE SUB mod.sub (args() AS ANY)
'$DYNAMIC
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

DIM SHARED blanksymbol AS symbol, symbols(100) AS symbol, outp AS symbol, vars(100) AS vars

CLS
p$ = "system(&BE_6502); include(&lcd); $lcd.init(:lcd.init.2ln); def(%i); start(); set(%i, 0); while(%i, { $lcd.print(*b2s(%i)); }); halt();"
t# = TIMER
PRINT "Stage 1 (preprocessor)...";
o$ = preprocess$(p$)
PRINT TIMER - t#; "s"
PRINT , "Output: "; o$

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

SUB mod.asm (args() AS symbol)
 outp.outp = args(0).outp
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
    outp.outp = args(0).outp + " BNE " + label$ + args(1).outp + label$ + ":"
   CASE "-Z"
    outp.outp = args(0).outp + " BEQ " + label$ + args(1).outp + label$ + ":"
   CASE "+C"
    outp.outp = args(0).outp + " BCC " + label$ + args(1).outp + label$ + ":"
   CASE "-C"
    outp.outp = args(0).outp + " BCS " + label$ + args(1).outp + label$ + ":"
  END SELECT
 ELSE
  outp.outp = args(0).outp + " BNE " + label$ + args(1).outp + label$ + ":"
 END IF
END SUB

SUB mod.sub (args() AS symbol)
 lbl$ = addlabel
 args(2).outp = lbl$
 args(2).type = "$"
 args(2).name = "$" + args(0).outp
 sr& = addsymbol(args(2))
 outp.outp = lbl$ + ":" + args(1).outp + "  RTS"
END SUB

SUB parse (line$)
 DIM char AS STRING * 1

END SUB

FUNCTION postprocess$ (c$)

END FUNCTION

FUNCTION preprocess$ (program AS STRING)
 DIM c AS STRING * 1 ', n AS STRING * 1
 PRINT "INF> preprocess: Running stage 1..."

 FOR i& = 1 TO LEN(program)
  c = MID$(program, i&, 1)
  SELECT CASE ASC(c)

   CASE 34
    i2& = INSTR(i& + 1, program, c)
    IF i2& = 0 THEN
     PRINT "ERR> preprocess: could not find closing quotation!"
     PRINT MID$(program, i& - 10, 10)
     PRINT SPACE$(9); "^"
     'SYSTEM   'we don't need compilers telling us what to do!
    ELSE 'im just gonna ignore that

     o$ = o$ + MID$(program, i&, i2& - i&)
     i& = i2&
    END IF

   CASE ASC("<")
    i2& = INSTR(i& + 1, program, ">")
    IF i2& = 0 THEN
     PRINT "ERR> preprocess: could not find close of comment!"
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
 SELECT CASE modules$
  CASE "if": mod.if args()
   'CASE "while": mod.while args()
  CASE "sub": mod.sub args()
   'CASE "func": mod.func args()
  CASE "def": mod.def args()
  CASE "asm": mod.asm args()
  CASE "halt": mod.halt args()
  CASE ELSE: PRINT "ERR> run.mod: invalid module '"; module$; "'"
 END SELECT
END SUB

SUB run.sym (code$)
 outp.type = LEFT$(symname$, 1)
 symnale$ = MID$(symname$, 2)
 SELECT CASE outp.type
  CASE "$"
   'run.mod.sub symname$
  CASE "#"
   SELECT CASE ASC(symname$)
    CASE ASC("$")
     outp.value = VAL("&H" + MID$(symname$, 3))
    CASE ASC("%")
     outp.value = VAL("&B" + MID$(symname$, 3))
    CASE ASC("&")
     outp.value = VAL("&O" + MID$(symname$, 3))
    CASE ELSE
     IF LTRIM$(RTRIM$(STR$(VAL(symname$)))) = symname$ THEN
      outp.value = VAL(symname$)
     ELSE
      PRINT "ERR> run.sym: '#"; symname$; "' when expected decimal number"
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
   PRINT "ERR> run.sym: cannot determine type of symbol '"; outp.type; symname$; "'"
 END SELECT
END SUB

