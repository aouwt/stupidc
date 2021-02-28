DECLARE SUB Get.Sub (SubName$, Args() AS ANY)
DECLARE SUB Mod.Asm (Args() AS ANY)
DECLARE SUB Mod.Def (Args() AS ANY)
DECLARE SUB Mod.Halt (Args() AS ANY)
DECLARE SUB Mod.If (Args() AS ANY)
DECLARE SUB Mod.Include (Args() AS ANY)
DECLARE SUB Mod.Onreset (Args() AS ANY)
DECLARE SUB Mod.Sub (Args() AS ANY)
DECLARE SUB Mod.System (Args() AS ANY)
DECLARE SUB Mod.Undef (Args() AS ANY)
'$INCLUDE: 'A:\COMMON.BI'

SUB Func.Or (Args() AS Symbol)
  
END SUB

SUB Func.Pull (Args() AS Symbol)
  S(Outp.Outp) = "FS_PULL"
END SUB

SUB Mod.Asm (Args() AS Symbol)
  IF Args(0).Type <> CHR$(34) THEN
    LogP "WARN> Mod.Asm: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '" + CHR$(34) + "'"
  END IF

  S(Outp.Outp) = S(Args(0).Outp)
END SUB

SUB Mod.C.Print (Args() AS Symbol)
  IF Args(0).Type <> CHR$(34) THEN
    LogP "WARN> Mod.C.Print: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '" + CHR$(34) + "'"
  END IF

  LogP "NOTICE> " + S(Args(0).Outp)
END SUB

SUB Mod.Def (Args() AS Symbol)
  IF Args(0).Type <> "%" THEN
    LogP "WARN> Mod.Def: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '%'"
  END IF

  DO
    i& = i& + 1
  LOOP UNTIL (ASC(Vars(i&).Name) = 32) OR (i& >= UBOUND(Vars))

  IF i& > UBOUND(Vars) THEN LogP "ERROR> mod.Def: Out of variable space for variable '" + Args(0).Name + "'"

  Vars(i&).Name = Args(0).Name
  Vars(i&).Address = Vars(i& - 1).Address + 1
END SUB

SUB Mod.Halt (Args() AS Symbol)
  S(Outp.Outp) = " JMP *"
END SUB

SUB Mod.If (Args() AS Symbol)
  IF Args(1).Type <> "{" THEN
    LogP "WARN> Mod.If: Cannot use type '" + Args(1).Type + "' as second argument. Using as if it were '{'"
  END IF

  Label$ = AddLabel
  IF Args(0).Type = "?" THEN

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
  IF Args(0).Type <> "&" THEN
    LogP "WARN> Mod.Include: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '&'"
  END IF

  LogP "INFO> mod.Include: Loading file '" + S(Args(0).Outp) + "'"

  'S(Outp.Outp) = ""

  Parse Preprocess$(LOADFILE$("A:\STUPIDC\LIBS\" + S(Args(0).Outp) + ".SC"))

  LogP "INFO> mod.Include: Exiting include '" + S(Args(0).Outp) + "'"
END SUB

SUB Mod.Onreset (Args() AS Symbol)
  IF Args(0).Type <> "{" THEN
    LogP "WARN> Mod.Onreset: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '{'"
  END IF

  S(Outp.Outp) = "cpu_reset:" + nl + S(Args(0).Outp) + nl + " JMP *"
END SUB

SUB Mod.Sub (Args() AS Symbol)
  IF Args(0).Type <> "&" THEN
    LogP "WARN> Mod.Sub: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '&'"
  END IF

  IF Args(1).Type <> "{" THEN
    LogP "WARN> Mod.Sub: Cannot use type '" + Args(1).Type + "' as second argument. Using as if it were '{'"
  END IF


  lbl$ = AddLabel
  S(Args(2).Outp) = lbl$
  Args(2).Type = "$"
  Args(2).Name = "$" + S(Args(0).Outp)
  sr& = AddSymbol(Args(2))
  S(Outp.Outp) = lbl$ + ":" + S(Args(1).Outp) + " RTS"
END SUB

SUB Mod.System (Args() AS Symbol)
  IF Args(0).Type <> "&" THEN
    LogP "WARN> Mod.System: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '&'"
  END IF

  SCS.Load "A:\STUPIDC\SCS\" + S(Args(0).Outp) + ".SCS"
END SUB

SUB Mod.Undef (Args() AS Symbol)
  IF Args(0).Type <> "%" THEN
    LogP "WARN> Mod.Undef: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '%'"
  END IF

  DO
    i& = i& + 1
  LOOP UNTIL (Vars(i&).Name = Args(0).Name) OR (i& >= UBOUND(Vars))
  
  IF i& >= UBOUND(Vars) THEN LogP "ERROR> Mod.Undef: Variable '" + Args(0).Name + "' is not defined!": EXIT SUB
  IF ASC(Vars(i& - 1).Name) <> 32 THEN LogP "WARN> Mod.Undef: Variable '" + Args(0).Name + "' is buried! undef-ing this variable can cause issues!"

  Vars(i&).Name = ""
END SUB

SUB ModRun.F (Funcname$, Args() AS Symbol)
  SELECT CASE Funcname$

    CASE "pull"
      'Func.Pull args()

  END SELECT
END SUB

SUB ModRun.R (module$, Args() AS Symbol)
  IF ASC(module$) = ASC("$") THEN Get.Sub MID$(module$, 2), Args()

  ASMOutput = ASMOutput + ";ModRun.R " + module$ + nl
  'LogP module$

  S(Outp.Outp) = ""
  SELECT CASE module$

    CASE "asm": Mod.Asm Args()

    CASE "def": Mod.Def Args()

    CASE "halt": Mod.Halt Args()

    CASE "if": Mod.If Args()

    CASE "include", "lib": Mod.Include Args()'TODO: Make difference between lib() and include()

    CASE "onreset": Mod.Onreset Args()

    CASE "sub": Mod.Sub Args()

    CASE "system": Mod.System Args()

    CASE "undef": Mod.Undef Args()

    CASE ELSE
      LogP "ERROR> ModRun.R: invalid module '" + module$ + "'"
  END SELECT
END SUB

