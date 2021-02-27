# stupidc
Stupid programming language that vaguely resembles C and compiles directly to 6502 assembly

## compiling
tested and works in QBX PDS 7.1 and VBDOS (it probably can run in other earlier versions of VB but I havent tested it.) it ***cannot*** run in QBasic, QB45, or QB64 due to issues with UDTs.

## sample program
parser doesnt work yet but this is what a Hello World should look like (so far)

### hello world
```stupidc
system(&BE6502);
include(&LCD);

onreset({
  $lcd.init(:lcd.c.2l);
  $lcd.print(#"Hello, world!");
});
```

#### hello world but more annoying
```stupidc
system(&BE6502);
include(&LCD);
def(%i);

onreset({
  $lcd.init(:lcd.c.2l);
  set(%1,0);

  while(%i,{
    $lcd.print(#"Hello, world!");
    inc(%i);
  });
});
```

### learn how to count with stupidc!
```stupidc
system(&BE6502);
include(&LCD);
def(%i);

onreset({
  $lcd.init(:lcd.c.2l);
  
  while(%i,{
    $lcd.print(*b2s(%i));
    inc(%i);
  )};
  
});

```

### interrupt handling demo
```stupidc
system(&BE6502);
include(&LCD);

onreset({
  $lcd.init(:lcd.c.2l);
  $lcd.print(#"Reset");
)};

onirq({
  $lcd.init(:lcd.c.2l);
  $lcd.print(#"IRQ");
  
  $lcd.locate(:lcd.c.ln2);
  $lcd.print(#"IRQ OFF");
  
  irq(&OFF);
)};

onnmi({
  $lcd.init(:lcd.c.2l);
  $lcd.print(#"NMI");
  
  $lcd.locate(:lcd.c.ln2);
  $lcd.print(#"IRQ ON");
  
  irq(&on);
});
```

### h
```stupidc
system(&BE6502);
include(&LCD);

onreset({
  $lcd.init(:lcd.c.2l);

  while(#1,{
    $lcd.print(#\`h);
  });
});
```
