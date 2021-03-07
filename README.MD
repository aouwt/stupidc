# stupidc
stupid programming language that vaguely resembles C and compiles directly to 6502 assembly

## compiling
open MAIN.MAK in QB71 or VB for DOS and press <kbd>F5</kbd>. ***it is important that you use QBX or VB4DOS; it cannot run in QBasic, QB45, or QB64 due to issues with UDTs.*** it also cannot run in any other versions of VisualBasic because they are completely different languages (confusing, right?)

## code structures
everything is pretty straightfoward, really. it's organized like this:

- MAIN.BAS is the main module. it has the parser and controls everything
  - COMMON.BI is the declarations for the common variables and subs. it MUST be INCLUDEd into EVERY module
  - SETUP.BI sets up all the variables, arrays, and parses the command-line options. I used it as an INCLUDE because it makes it neater, and makes it separate from the actual compiler. for ...reasons it also has all the INCLUDE and DECLARE statements for the main module
  - DEFAULTS.BI is the configuration for the compiler. nothing important, really.
- SCS.BAS is the module that handles parsing SCS files. pretty straightfoward.
- SCMODS.BAS is the stupidc "modules," as i like to call them. they are the things that turn the commands in the inputted program (after they're parsed) and outputs assembly code
  - SCMODS.BI is to be deleted later, the SUBs used in SCMODS.BAS aren't needed outside it except for ModRun.R and ModRun.F

keep in mind that this is supposed to run in a DOS enviroment, so filenames should keep to the limitations of most DOS enviroments: no special charaters, no_spaces, 8.3 filenames, and UPPERCASE only. the only exception to this is the .git folder (i think it's case-sensitive, but i need to check that) and .gitignore, but you really shouldn't be editing those from DOS.

## sample programs
doesnt work quite yet but you can find samples in the [SAMPLES folder](https://github.com/all-other-usernames-were-taken/stupidc/tree/main/SAMPLES).
(i know they're labled as Scala programs, but 'cmon, what other extension should i have chosen?)
