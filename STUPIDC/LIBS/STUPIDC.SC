<STUPIDC.SC
 (c)2021 all-other-usernames-were-taken
 Bundeled as a part of stupidc (https://github.com/all-other-usernames-were-taken/stupidc)
 Documentation can be found at https://github.com/all-other-usernames-were-taken/stupidc/wiki/STUPIDC.SC
>

<---------------->

func(&multiply, {
	def(%arg1);
	def(%arg2);
	def(%result);
	
	set(%arg1, .pull());
	set(%arg2, .pull());
	
	set(%result, #0);
	
	while(%arg1, {
		set(%result, .add(%result, %arg2));
		dec(%arg1);
	});
	
	return(%result);
	
	undef(%result);
	undef(%arg1);
	undef(%arg2);
});



sub(&delay, {
	def(%arg);
	def(%counter1);
	def(%counter2);
	
	set(%arg, .pull());
	
	set(%counter1, %arg);
	while(%counter1, {
		
		set(%counter2, %arg);
		while(%counter2, {
			dec(%counter2);	
		});
		
		dec(%counter1);
		
	});
	
	undef(%arg);
	undef(%counter2);
	undef(%counter2);
});
