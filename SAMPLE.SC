system(#"BE6502.SCS");

<include(#"LCD.SC");
include(#"VIA.SC");
include(#"STUPIDC.SC");>

def(%count);
def(%lives);
mem(%score, #1); < 2 byte (integer)>
mem(%hscore, #1);

reset({
 set(%lives, #3);
 set(%count, #$FF);
 set(%score.0, #0);
 set(%score.1, #0);
 
 $lcd.init(:lcd.init.2ln);
 $readyseq();
 
 
 while(?ne(%lives, #0), {
  inc(%count);
  
  if(?eq(%count, #0), {
   dec(%lives);
   $lcd.locate(:lcd.locate.ln2);
   ~lcd.print(#"Oops...");
   
   if(?eq(%lives, #0), {
    $via.wait(#3);
    $gameover();
    halt();
   },{
    $readyseq();
   });
   
  });
  
  if(?bit(#3, %count), {  <essentially mod 16>
   $lcd.printchr(#'#');
  });
  
 });
 
});



irq({
 irqmode(&OFF);
 
 wset(wadd(%score, .b2w(%count)));
 
 $lcd.clear();
 $lcd.locate(:lcd.locate.ln2);
 ~lcd.print(*sc.i2s(%score));
 $lcd.locate(.comp.add(:lcd.locate.ln2, #8));
 $readyseq();
 
 irqmode(&ON);
});



sub($readyseq, {
 def(%locate);
 set(%locate, *lcd.location());
 
 $lcd.printchr(#'3');
 $lcd.locate(%locate);
 ~via.wait(#1);
 
 $lcd.printchr(#'2');
 $lcd.locate(%locate);
 $via.wait(#1);
 
 $lcd.printchr(#'1');
 $via.wait(#1);
 
 $lcd.clear();
 set(%count, #$ff);
});



sub($gameover, {
 $lcd.clear();
 $lcd.locate(#0);
 ~lcd.print(#"Game over");
 
 $lcd.locate(:lcd.locate.ln2);
 ~lcd.print(#"S:");
 ~lcd.print(*sc.i2s(%score));
 
 $lcd.locate(.comp.add(:lcd.locate.ln2, #8));
 ~lcd.print(#"H:");
 ~lcd.print(*sc.i2s(%hscore));
 
 $via.wait(#FF);
 $lcd.locate(#0);
 
 ~lcd.print(#"Press reset");
});

