# stupidc
Stupid programming language that vaguely resembles C and compiles directly to 6502 assembly

## compiling
compile (or interpret) with [QB64](https://github.com/QB64Team/qb64) or QB 7.1 (probably will be able to compile on other versions of MS QB, but I haven't tested it yet.)

## sample program
parser doesnt work yet but this is what a Hello World should look like (so far)

### hello world
```stupidc
system(&BE6502);
include(&lcd);

$lcd.init(&2l);

$lcd.print(:hworld);
halt();

data(:hworld, #"Hello, world!");
```

#### hello world but more annoying
```stupidc
system(&BE6502);
include(&lcd);

$lcd.init(&2l);

def(%i);
set(%1,0);

while(%i,{
  $lcd.print(:hworld);
  inc(%i);
});

halt();

data(:hworld, #"Hello, world!");
```

### learn how to count with stupidc!
```stupidc
system(&BE6502);
include(&lcd);

$lcd.init(&2l);

def(%i);

while(%i,{
  $lcd.print(*b2s(%i));
  inc(%i);
});

halt();
```

### h
```stupidc
system(&B6502);
include(&lcd);

$lcd.init(&2l);

while(#1,{
  $lcd.print(#'h');
});
```
