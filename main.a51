	; -- [Aufgabenstellung] -- ;
	; - Schreiben sie ein Programm zur Berechnung von Apfelm�nnchen -- ;
	; - A, B, Px und Nmax sind als Konstanten zu definieren
	; - Die Farbwerte der einzelnen Punkte c sind als ASCII-Zeichen �ber die serielle Schnittstelle auszugeben
	
	
	; -- Folgende UP werden ben�tigt -- ;
	; - Berechnung des ASCII Werts abh�ngig von n
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
	
	MOV R6, #000011$0000000000b
	MOV R5, #000001$0000000000b
	MOV R4, #000010$0000000000b
	MOV R3, #000100$0000000000b
	
	;ADD A und B;
	
	;Realteil;
	MOV A, R6
	ADD A, R4
	MOV R6, A
	
	;Imagin�rteil;
	MOV A, R5
	ADD A, R3
	MOV R5, A
	
	
	;UP: Addieren von zwei komplexen Zahlen A und B im Format VVVVVV.NNNNNNNNNN + i * VVVVVV.NNNNNNNNNN;
	;zu Zahl C im gleichen Format;
	;Registerbelegung: Re(A): R6 | Im(A): R5 | Re(B): R4 | Im(B): R3;
	;Ausgabe: Re(C): R6 | Im(C): R5;
	
	
	
	
	
	
	
	
	
	
	
	; -- [Berechung von ASCII abh�ngig von n] -- ;
	; MOV R7, #10000
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
	
	; A enth�lt Ergebnis der Division, B den Rest -> Rest in A schieben
	MOV A, B
	
	; Nun wird der f�r den gegebenen Rest das jeweilige UP aufgerufen, welches das ASCII-codierte Zeichen in R7 schreibt
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
	; - keine Parit�t und kein Handshaking
	; - Baudrate 28800 1/s
	
	MOV 098h, #80d
	
	; Baudgenerator benutzen
	MOV 0DFh, #1d
	
	; S0REL einstellen
	;MOV S0RELL, #0xD9
	;MOV S0RELH, #0x03
	

	
	
	; ASCII Byte senden
	MOV 099h, R7
	
	;JNB TI0, $
	
	;CLR TI0
	
	;wait_for_receive:
	;	JNB RI0, wait_for_receive
	
	;MOV A, S0BUF
	NOP
	
	
	
	
	
	NOP
	NOP
	
	END