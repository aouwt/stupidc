system (&BE6502);
include (&lcd);

def (%index);
def (%ptr);
reserve (%memory, #100);

const (%pgm, #"Your program code goes here");

onreset ({
	choose (%pgm@%index,
	
		#'+',{	inc (%memory@%ptr);	},
		
		#'-',{	dec (%memory@%ptr);	},
		
		#'>',{	inc (%ptr);	},
		
		#'<',{	dec (%ptr);	},
		
		#']',{
			if (%memory@%ptr, {
				while (?ne(%pgm@%index, #'['),{
					dec (%index);
			}); });
		},
		
		#'.',{	$lcd.prtchar (%memory@%ptr);	}
	);
	if (?gt(.dec(%ptr), .sizeof(%pgm)), {	halt();	});
});
