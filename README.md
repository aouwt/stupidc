# stupidc
Stupid programming language that vaguely resembles C and compiles directly to 6502 assembly

## compiling
use your choice of QuickBasic compiler/interpreter to run. note that it ***cannot*** run in QB64.

## sample program
parser doesnt work yet but this is what a Hello World should look like (so far)

### hello world
```stupidc
system(#"BE6502.SCS");
include(#"LCD.SC");

reset({
  $lcd.init(:lcd.init.2l);
  $lcd.print(#"Hello, world!");
});
```

#### hello world but more annoying
```stupidc
system(#"BE6502.SCS");
include(#"LCD.SC");
def(%i);

reset({
  $lcd.init(:lcd.init.2l);
  set(%1,0);

  while(%i,{
    $lcd.print(#"Hello, world!");
    inc(%i);
  });
});
```

### learn how to count with stupidc!
```stupidc
system(#"BE6502.SCS");
include(#"LCD.SC");
def(%i);

reset({
  $lcd.init(:lcd.init.2l);
  
  while(%i,{
    $lcd.print(*b2s(%i));
    inc(%i);
  )};
});

```

### interrupt handling demo
```stupidc
system(#"BE6502.SCS");
include(#"LCD.SC");

reset({
  $lcd.init(:lcd.init.2l);
  $lcd.print(#"Reset");
)};

irq({
  $lcd.init(:lcd.init.2l);
  $lcd.print(#"IRQ");
)};

nmi({
  $lcd.init(:lcd.init.2l);
  $lcd.print(#"NMI");
});
```

### h
```stupidc
system(#"BE6502.SCS");
include(#"LCD.SC");

reset({
  $lcd.init(:lcd.init.2l);

  while(#1,{
    $lcd.print(#'h');
  });
});
```
