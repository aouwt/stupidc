   LogFile = "A:\LOG.TXT"         'File to log to if -l is not specified
OutputFile = "A:\OUTPUT.ASM"      'File to output if -o is not specified
 InputFile = "A:\SAMPLES\CALC.SC" 'File to read from if not specified.

      ScrW = ScreenWidth          'Screen width for the log

 LogToFile = -1                   '0=Don't log to file; -1=Log to file
  LogToASM = -1                   '0=Don't log to output; -1=Copy log to output; -2=Log only modules used

'SCREEN 0 'SCREEN mode to use. Ususally you want to keep it at 0, or just comment it out.
WIDTH 80, 50 'Screen size. You ususally want to keep this commented out.


