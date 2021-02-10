# stupidc
Stupid programming language that vaguely resembles C and compiles directly to 6502 assembly

## compiling
compile (or interpret) with [QB64](https://github.com/QB64Team/qb64) or QB 7.1 (probably will be able to compile on other versions of MS QB, but I haven't tested it yet.)

## sample program
parser doesnt work yet but this is what a Hello World should look like (so far)

### hello world
```stupidc
system(&BE_6502);
include(&lcd);

reset({
  $lcd.init(:lcd.init.2l);
  $lcd.print(:hworld);
});

data(:hworld, #"Hello, world!");
```

#### hello world but more annoying
```stupidc
system(&BE_6502);
include(&lcd);
def(%i);

reset({
  $lcd.init(:lcd.init.2l);
  set(%1,0);

  while(%i,{
    $lcd.print(:hworld);
    inc(%i);
  });
});

data(:hworld, #"Hello, world!");
```

### learn how to count with stupidc!
```stupidc
system(&BE_6502);
include(&lcd);
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
system(&BE_6502);
include(&lcd);

reset({
  $lcd.init(:lcd.init.2l);
  $lcd.print(:reset);
)};

irq({
  $lcd.init(:lcd.init.2l);
  $lcd.print(:irq);
)};

nmi({
  $lcd.init(:lcd.init.2l);
  $lcd.print(:nmi);
});

data(:reset, #"Reset");
data(:irq, #"IRQ");
data(:nmi, #"NMI");
```

### h
```stupidc
system(&BE_6502);
include(&lcd);

reset({
  $lcd.init(:lcd.init.2l);

  while(#1,{
    $lcd.print(#'h');
  });
});
```
