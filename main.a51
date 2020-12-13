	; -- [Aufgabenstellung] -- ;
	; - Schreiben sie ein Programm zur Berechnung von Apfelm�nnchen -- ;
	; - A, B, Px und Nmax sind als Konstanten zu definieren
	; - Die Farbwerte der einzelnen Punkte c sind als ASCII-Zeichen über die serielle Schnittstelle auszugeben
	
	
	; -- Folgende UP werden benötigt -- ;
	; - Berechnung des ASCII Werts abhängig von n
	; - 
	
	; -- [Definieren der Konstanten] -- ;
	Nmax EQU 10000
	P_A_re EQU 5
	P_A_im EQU 4
	P_B_re EQU 5
	P_B_im EQU 4
	Px EQU 100
	
	;UP: Addieren von zwei komplexen Zahlen A und B im Format VVVVVV.NNNNNNNNNN + i * VVVVVV.NNNNNNNNNN;
	;zu Zahl C im gleichen Format;
	;Registerbelegung: Re(A): R6 | Im(A): R5 | Re(B): R4 | Im(B): R3;
	;Ausgabe: Re(C): R6 | Im(C): R5;
	
	;lade A in Speicher;
	
	//Re(A)
	MOV 0xA0h, #000011$00b
	MOV 0xA8h, #00000000b
	
	//Im(A)
	MOV 0xB0h, #000001$00b
	MOV 0xB8h, #00000000b 
	
	//Re(B)
	MOV 0xC0h, #000010$00b
	MOV 0xC8h, #00000000b
	
	//Im(B)
	MOV 0xD0h, #000011$00b
	MOV 0xD8h, #00000000b
	
	;ADD A und B;
	
	//Re(A) + Re(B)
	MOV R7, 0xA8h
	MOV A, R7
	ADD A, 0xC8h
	MOV 
	
	;Realteil;
	MOV A, R6
	ADD A, R4
	MOV R6, A
	
	;Imagin�rteil;
	MOV A, R5
	ADD A, R3
	MOV R5, A
		up1:MOV R6, #000011$0000000000b
	MOV R5, #000001$0000000000b
	MOV R4, #000010$0000000000b
	MOV R3, #000100$0000000000b
	
	
	
	
	
	
	
	
	; -- [Berechung von ASCII abh�ngig von n] -- ;
	MOV R7, #10000
calc_ascii:
	; n liegt in Register R7
	MOV A, R7

	; -- [Berechung von ASCII abh?ngig von n] -- ;
	; Zuerst �berpr�fen, ob n = Nmax gilt
	SUBB A, #Nmax
	CLR C
	
	JZ set_ascii_nmax ; ACC = 0, wenn n = Nmax
	
	; ACC != 0
	; -> Mod 8 rechnen
	MOV A, R7
	MOV B, #8d
	DIV AB
	
	; A enthält Ergebnis der Division, B den Rest -> Rest in A schieben
	MOV A, B
	
	; Nun wird der für den gegebenen Rest das jeweilige UP aufgerufen, welches das ASCII-codierte Zeichen in R7 schreibt
	; und danach das UP aufruft, welches das ASCII-Zeichen auf die serielle Schnittstelle schreibt
	
	; Rest 0
	JZ set_ascii_mod0 
	
	; Rest ist > 0
	SUBB A, #1
	JZ set_ascii_mod1
	
	; Rest ist > 1
	SUBB A, #1
	JZ set_ascii_mod2
	
	; Rest ist > 2
	SUBB A, #1
	JZ set_ascii_mod3
	
	; Rest ist > 3
	SUBB A, #1
	JZ set_ascii_mod4
	
	; Rest ist > 4
	SUBB A, #1
	JZ set_ascii_mod5
	
	; Rest ist > 5
	SUBB A, #1
	JZ set_ascii_mod6
	
	; Rest ist > 6
	SUBB A, #1
	JZ set_ascii_mod7
	
	; Rest ist > 7
	; -> Fehler?
	
set_ascii_mod0:
	MOV R7, #164d
	SJMP write_ascii
	
set_ascii_mod1:
	MOV R7, #43d
	SJMP write_ascii
	
set_ascii_mod2:
	MOV R7, #169d
	SJMP write_ascii
	
set_ascii_mod3:
	MOV R7, #45d
	SJMP write_ascii
	
set_ascii_mod4:
	MOV R7, #42d
	SJMP write_ascii
	
set_ascii_mod5:
	MOV R7, #64d
	SJMP write_ascii
	
set_ascii_mod6:
	MOV R7, #183d
	SJMP write_ascii
	
set_ascii_mod7:
	MOV R7, #174d
	SJMP write_ascii
	
set_ascii_nmax:
	MOV R7, #32d

	; -- [Schreiben von ASCII Wert auf die serielle Schnittstelle] -- ;
write_ascii:
	; -- Konfiguration der Schnittstelle -- ;
	; - Interface 0
	; - 1 Startbit, 8 Datenbit, 1 Stopbit
	; - keine Parität und kein Handshaking
	; - Baudrate 28800 1/s
	
	; S0CON undefined symbol -> Adresse benutzen (0x98)
	; SM0 = 0, 
	; SM1 = 1 -> Mode 1: 8-Bit, var. Baud
	; SM20 = 0 -> RI0 wird aktiviert
	; REN0 = 1 -> Receiver enable
	; TB80 = 0 -> kein 9. Datenbit
	; RB80 = 0 -> Stoppbit
	; TI0 = 0 -> Transmitter interrupt Flag
	; RI0 = 0 -> Receiver interrupt Flag
	; -> Bitfolge ergibt 80
	MOV 098h, #80d
	
	; Baudrate: 2^(SMOD)*OszilatorFrequenz/(64*(1024 - S0REL)) = 28800
	; smod=1, s0rel= 0xffe6
	; smod=0, s0rel = 0xfff3
	; -> Beide geben Baudrate von 28846
	
	; S0REL ist (S0RELH | S0RELL)
	; S0REL einstellen, auch hier Adressen (0xAA, 0xBA) benutzen
	MOV 0AAh, #0xf3 ; S0RELL
	MOV 0BAh, #0xff ; S0RELH
	
	; Baudgenerator benutzen
	SETB 0DFh	
	
	; ASCII Byte senden
	; S0BUF undefined -> 0x99
	MOV 099h, R7
	
	; Warte auf TI0
	; TI0 ist Bit 1 von S0CON
	wait_for_send:
		JNB 099h, wait_for_send
	
	; Entferne TI0 Flag
	ANL 098h, #1111$1101b

	; Warte auf RI0
	; RI0 ist Bit 0 von S0CON
	wait_for_receive:
		; Reset Watchdog
		ORL 0A8h, #0100$0000
		ORL 0B8h, #0100$0000
		JNB 098h, wait_for_receive
		
	; Entferne RI0 Flag
	ANL 098h, #1111$1110b
	
	MOV A, 099h
	
	NOP
	NOP
	
	END