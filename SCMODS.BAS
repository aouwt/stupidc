DECLARE SUB Mod.OnIRQ (Args() AS ANY)
DECLARE SUB Mod.OnNMI (Args() AS ANY)
DECLARE SUB Mod.Set (Args() AS ANY)
DECLARE SUB S.Free (h AS INTEGER)
DECLARE SUB Run.Sub (SubName$, Args() AS ANY)
DECLARE SUB Get.Sub (SubName$, Args() AS ANY)
DECLARE SUB Mod.Asm (Args() AS ANY)
DECLARE SUB Mod.Def (Args() AS ANY)
DECLARE SUB Mod.Halt (Args() AS ANY)
DECLARE SUB Mod.If (Args() AS ANY)
DECLARE SUB Mod.Include (Args() AS ANY)
DECLARE SUB Mod.OnReset (Args() AS ANY)
DECLARE SUB Mod.Sub (Args() AS ANY)
DECLARE SUB Mod.System (Args() AS ANY)
DECLARE SUB Mod.Undef (Args() AS ANY)
REM $INCLUDE: 'A:\COMMON.BI'

SUB Func.Or (Args() AS Symbol)
  S(Outp.Outp) = S(Args(0).Outp) + NL + " STA TEMP" + NL + S(Args(1).Outp) + " ORA TEMP"
END SUB

SUB Func.Pull (Args() AS Symbol)
  S(Outp.Outp) = " PULL"
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

'
SUB Mod.Dec (Args() AS Symbol)
  S(Outp.Outp) = " DEC VAR_" + Args(0).Name
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

SUB Mod.Inc (Args() AS Symbol)
  S(Outp.Outp) = " INC VAR_" + Args(0).Name
END SUB

SUB Mod.Include (Args() AS Symbol)
  IF Args(0).Type <> "&" THEN
    LogP "WARN> Mod.Include: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '&'"
  END IF

  LogP "INFO> mod.Include: Loading file '" + S(Args(0).Outp) + "'"

  'S(Outp.Outp) = ""

  Parse Preprocess$(LOADFILE$("A:\STUPIDC\LIBS\" + S(Args(0).Outp) + ".SC"))

  'LogP "INFO> mod.Include: Exiting include '" + S(Args(0).Outp) + "'"
END SUB

SUB Mod.IRQ (Args() AS Symbol)
  IF Args(0).Type <> "&" THEN
    LogP "WARN> Mod.IRQ: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '&'"
  END IF
  
  IF Args(0).Name = "ON" THEN
    S(Outp.Outp) = " SEI"

  ELSEIF Args(0).Name = "OFF" THEN
    S(Outp.Outp) = " CLI"

  ELSE
    LogP "ERROR> Mod.IRQ: Expected '&ON' or '&OFF', got '" + RTRIM$(Args(0).Name) + "'"

  END IF
END SUB

SUB Mod.OnIRQ (Args() AS Symbol)
  IF Args(0).Type <> "{" THEN
    LogP "WARN> Mod.Onirq: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '{'"
  END IF

  S(Outp.Outp) = "CPU_IRQ:" + NL + S(Args(0).Outp) + NL + " RTI"

END SUB

SUB Mod.OnNMI (Args() AS Symbol)
  IF Args(0).Type <> "{" THEN
    LogP "WARN> Mod.OnNMI: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '{'"
  END IF

  S(Outp.Outp) = "CPU_NMI:" + NL + S(Args(0).Outp) + NL + " RTI"

END SUB

SUB Mod.OnReset (Args() AS Symbol)
  IF Args(0).Type <> "{" THEN
    LogP "WARN> Mod.Onreset: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '{'"
  END IF

  S(Outp.Outp) = "CPU_RESET:" + NL + S(Args(0).Outp) + NL + " JMP *"
END SUB

SUB Mod.Set (Args() AS Symbol)
  IF Args(0).Type <> "%" THEN
    LogP "WARN> Mod.Set: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '%'"
  END IF

  S(Outp.Outp) = S(Args(1).Outp) + NL + " STA VAR_" + Args(0).Name
END SUB

SUB Mod.Sub (Args() AS Symbol)
  IF Args(0).Type <> "$" THEN
    LogP "WARN> Mod.Sub: Cannot use type '" + Args(0).Type + "' as first argument. Using as if it were '$'"
  END IF

  IF Args(1).Type <> "{" THEN
    LogP "WARN> Mod.Sub: Cannot use type '" + Args(1).Type + "' as second argument. Using as if it were '{'"
  END IF


  S(Outp.Outp) = NL + "SR_" + RTRIM$(Args(0).Name) + ":" + NL + S(Args(1).Outp) + NL + " RTS" + NL

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
  IF ASC(module$) = ASC("$") THEN Run.Sub MID$(module$, 2), Args()

  LogP "DEBUG> ModRun.R: Running " + module$

  Outp.Outp = S.Reserve
  SELECT CASE module$

    CASE "asm": Mod.Asm Args()

    CASE "def": Mod.Def Args()

    CASE "halt": Mod.Halt Args()

    CASE "if": Mod.If Args()

    CASE "include", "lib"
      IF module$ = "lib" THEN LogP "WARN> ModRun.R: 'lib' is not supported yet, using 'include' instead"
      Mod.Include Args()'TODO: Make difference between lib() and include()

    CASE "onirq": Mod.OnIRQ Args()

    CASE "onnmi", "nmi"
      IF module$ = "nmi" THEN LogP "WARN> ModRun.R: 'nmi' is not recommended, use 'onnmi' instead"
      Mod.OnNMI Args()

    CASE "onreset", "reset"
      IF module$ = "reset" THEN LogP "WARN> ModRun.R: 'reset' is not recommended, use 'onreset' instead"
      Mod.OnReset Args()

    CASE "set": Mod.Set Args()

    CASE "sub": Mod.Sub Args()

    CASE "system": Mod.System Args()

    CASE "undef": Mod.Undef Args()

    CASE ELSE
      LogP "ERROR> ModRun.R: invalid module '" + module$ + "'"

      FOR i% = 0 TO UBOUND(Args)
        IF Args(i%).Type = "{" THEN

          LogP "WARN> ModRun.R: Invalid module has '{' type argument, bypassing module and putting direcly into ASMOutput."
          ASMOutput = ASMOutput + S(Args(i%).Outp) + NL
          'S.Free Args(i%).Outp

        END IF
      NEXT

      S.Free Outp.Outp

  END SELECT
END SUB


