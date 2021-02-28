'$INCLUDE: 'A:\COMMON.BI'

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

  f% = FREEFILE
  LogP "INFO> SCS.Load: Loading SCS file '" + Filename$ + "'"
  IF FILEEXISTS(Filename$) = 0 THEN LogP "ERROR> SCS.Load: File not found!": EXIT SUB
  OPEN Filename$ FOR INPUT AS #f%

  DO
    LINE INPUT #f%, ln$
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

          LINE INPUT #f%, ln$
          ln$ = LTRIM$(RTRIM$(ln$))
          IF ln$ = "}" THEN EXIT DO
          Val$ = Val$ + ln$ + CHR$(10) + CHR$(13)

        LOOP UNTIL EOF(f%)
        IF EOF(f%) THEN LogP "WARN> SCS.Load: Unexpected EOF while reading multi-line key '" + Key$ + "'"

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
  LOOP UNTIL EOF(f%)
END SUB

