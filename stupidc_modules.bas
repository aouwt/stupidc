SUB mod.asm (args() AS symbol)
    outp.outp = args(0).outp
END SUB

SUB mod.def (args() AS symbol)
    DO: i& = i& + 1: LOOP UNTIL vars(i&).name = ""
    vars(i&).name = args(0).name
    vars(i&).address = vars(i& - 1).address + 1
END SUB

SUB mod.if (args() AS symbol)
    label$ = addlabel
    IF args(0).type = "?" THEN
        SELECT CASE args(0).return
            CASE "+Z"
                outp.outp = args(0).outp + "  BNE " + label$ + args(1).outp + label$ + ":"
            CASE "-Z"
                outp.outp = args(0).outp + "  BEQ " + label$ + args(1).outp + label$ + ":"
            CASE "+C"
                outp.outp = args(0).outp + "  BCC " + label$ + args(1).outp + label$ + ":"
            CASE "-C"
                outp.outp = args(0).outp + "  BCS " + label$ + args(1).outp + label$ + ":"
        END SELECT
    ELSE
        outp.outp = args(0).outp + "  BNE " + label$ + args(1).outp + label$ + ":"
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

SUB mod.const (args() AS symbol)

END SUB

