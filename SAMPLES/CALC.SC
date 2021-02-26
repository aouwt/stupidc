system(#"BE6502");

lib(#"STUPIDC");
lib(#"LCD");

onreset({
	def(%i);
	def(%a);
	
	$lcd.init(:lcd.2l);
	$lcd.print(#"Hello, world!");
	
	set(%i, #1);
	while(%i, {
		$lcd.locate(:lcd.l2);
		$lcd.print(*b2s(%i));
		inc(%i);
	});
	
	$sc.delay(#$FF);
	
	set(%i, #$FF);
	while(%i, {
		$lcd.locate(:lcd.l2);
		$lcd.print(*b2s(%i));
		dec(%i);
	});
	
	$sc.delay(#$FF);
	
	set(%i, #1);
	set(%a, #1);
	while(%a, {
		while(%i, {
			$lcd.locate(:lcd.l2);
			
			$lcd.print(*b2s(%i));
			$lcd.print(#" x ");
			$lcd.print(*b2s(%a));
			$lcd.print(#" = ");
			$lcd.print(*b2s(*mult(%i, #10)));
		
			inc(%i);
		});
		
		inc(%a);
	});
});


onirq({
	$lcd.init(:lcd.2l);
	$lcd.print(*flip(#"Hello, world!"));
	
	$sc.delay(#$FF);
	
	set(%i, #1);
	while(%i, {
		$lcd.locate(:lcd.l2);
		
		$lcd.print(*b2s(%i));
		$lcd.print(#" x 5 = ");
		$lcd.print(*b2s(*mult(%i, #10)));
		
		inc(%i);
	});	
});


func(&flip, {
	def(%inp, #16);
	def(%i);
	
	set(%i, #0);
	set(%inp@#0, #1);
	
	while(%inp@%i, {
		set(%inp@%i, .pull())
		inc(%i);
	});
	
	while(%i, {
		push(%inp@%i);
		dec(%i);
	});
	
	undef(%inp);
	undef(%i);
});
