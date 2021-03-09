<LCD.SC
 (c)2021 all-other-usernames-were-taken
 Bundeled as a part of stupidc (https://github.com/all-other-usernames-were-taken/stupidc)
 Documentation can be found at https://github.com/all-other-usernames-were-taken/stupidc/wiki/LCD.SC
>

<---------------->
include(#"VIA");
include(#"STUPIDC");

def(%print.char);
def(%printchar.char);


sub(&lcd.print, {
	
	loop({
		set(%print.char, .pull()); <Pull the character from the stack>
		
		if(?eq(%print.char, #0), { exitloop(); }); <If character value is 0, then stop.>
		
		$lcd.printchar(%print.char);
	});
});


sub(&lcd.printchar, {
	
	$lcd.wait();
	
	set(`via.b, .pull());
	
	set(`via.a, :lcd.r.regsel);       <Set regsel & clear other regs>
	set(`via.a, .p.or(:lcd.r.regsel, :lcd.r.enable)); <Set enable>
	
	set(`via.a, :lcd.r.regsel);       <Clear enable>
});


sub(&lcd.locate, {
	$lcd.instruct( .or(:lcd.i.locate, .pull()) );
});


sub(&lcd.instruct, {
	
	$lcd.wait();
	
	set(`via.b, .pull()); <set PB>
	
	set(`via.a, #0); <Clear regs>
	set(`via.a, :lcd.r.enable); <set enable>});
	
	set(`via.a, #0); <clear regs>
	
});


sub(&lcd.wait, {
	set(`via.io.b, #0); <Set PB as input>
	
	while( .and(`via.b, :lcd.r.busy), {
		set(`via.a, :lcd.r.rw);
		set(`via.a, .or(:lcd.r.rw, :lcd.r.enable) );
	});
	
	set(`via.a, :lcd.r.rw);
	set(`via.io.b, #$FF); <PB is output>
});

