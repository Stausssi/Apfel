$NOMOD51
#include <Reg517a.inc>

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
	
	;lade A = 3.0 + 1.0 i in Speicher;
	
	//Re(A)
	MOV 020h, #000011$00b
	MOV 021h, #00000000b
	
	//Im(A)
	MOV 022h, #000001$00b
	MOV 023h, #00000000b 
	
	;lade B = 2.0 + 3.0 i in Speicher;
	
	//Re(B)
	MOV 024h, #000010$00b
	MOV 025h, #00000000b
	
	//Im(B)
	MOV 026h, #000011$00b
	MOV 027h, #00000000b
	
	
	//ADD A + B
	
	//Realteil
addAandB:CLR C // clear carry flag
	
	MOV R6, 021h //Re(A)LSB
	MOV A, R6
	ADD A, 025h  //Re(B)LSB
	MOV 021h, A // zurück nach LSB von Re(A)
	
	MOV R6, 020h //Re(A) MSB
	MOV A, R6
	ADDC A, 024h // Re(B) MSB
	MOV 020h, A // zurück nach MSB von Re(A)
	
	//Imaginärteil
	CLR C // clear carry flag
	
	MOV R6, 023h //Im(A)LSB
	MOV A, R6
	ADD A, 027h  //Im(B)LSB
	MOV 023h, A // zurück nach LSB von Im(A)
	
	MOV R6, 022h //Im(A) MSB
	MOV A, R6
	ADDC A, 026h // Im(B) MSB
	MOV 022h, A // zurück nach MSB von Im(A)
	

	//A^2 berechnen
	
	
	//......................
	
	
	
	
	//Multiplikation von zwei 16 Bit Zahlen nach folgendem Schema: 
	
	//         High  Low
	//
	//           A1  A2
	//	  *      B1  B2
	//-------------------
	//           H22 L22
	// +     H21 L21     
	// +     H12 L12
	// + H11 L11
	//-------------------
	//   P1  P2  P3  P4
	//s
	//   02C 02D 02E 02F  <== Output auf folgende feste Speicherstellen
	//
	//Die Zahlen signalisieren, welche Werte multipliziert wurden. z.B. L21: Lowbyte von B2 * A1
	//Dabei gilt:
	//
	// In R6: P1 <= H11 + carry from P2
	// In R5: P2 <= H21 + H12 + L11 + carry from P3 
	// In R4: P3 <= H22 + L21 + L12
	// In R3: P4 <= L22
	
	//Input Werte im Speicher an folgenden festen Speicherstellen:
	
	//(A)
	MOV 028h, #000011$00b //A1
	MOV 029h, #00000000b  //A2
	
	//(B)
	MOV 02Ah, #000010$00b //B1
	MOV 02Bh, #00000000b  //B2
	
	//Berechnung:
mult:
	// A2 * B2
	MOV A, 029h // A2
	MOV B, 02Bh // B2
	MUL AB //L22 in A, H22 in B
	
	MOV R3,A //L22
	MOV R4,B //H22
	
	// B2 * A1 
	MOV A, 02Bh // B2
	MOV B, 028h // A1
	MUL AB //L21 in A, H21 in B
	
	// P3 + L21 (in A)
	ADD A, P3
	.....
	
	

	
	
	
	
	
	
	
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
	LJMP write_ascii
	
set_ascii_mod1:
	MOV R7, #43d
	LJMP write_ascii
	
set_ascii_mod2:
	MOV R7, #169d
	LJMP write_ascii
	
set_ascii_mod3:
	MOV R7, #45d
	LJMP write_ascii
	
set_ascii_mod4:
	MOV R7, #42d
	LJMP write_ascii
	
set_ascii_mod5:
	MOV R7, #64d
	LJMP write_ascii
	
set_ascii_mod6:
	MOV R7, #183d
	LJMP write_ascii
	
set_ascii_mod7:
	MOV R7, #174d
	LJMP write_ascii
	
set_ascii_nmax:
	MOV R7, #32d

	; -- [Schreiben von ASCII Wert auf die serielle Schnittstelle] -- ;
write_ascii:
	; -- Konfiguration der Schnittstelle -- ;
	; - Interface 0
	; - 1 Startbit, 8 Datenbit, 1 Stopbit
	; - keine Parität und kein Handshaking
	; - Baudrate 28800 1/s
	
	; S0CON einstellen
	; SM0 = 0, 
	; SM1 = 1 -> Mode 1: 8-Bit, var. Baud
	; SM20 = 0 -> RI0 wird aktiviert
	; REN0 = 1 -> Receiver enable
	; TB80 = 0 -> kein 9. Datenbit
	; RB80 = 0 -> Stoppbit
	; TI0 = 0 -> Transmitter interrupt Flag
	; RI0 = 0 -> Receiver interrupt Flag
	; -> Bitfolge ergibt 80 (50h)
	MOV S0CON, #80d
	
	; Baudrate: 2^(SMOD)*OszilatorFrequenz/(64*(1024 - S0REL)) = 28800
	; smod=1, s0rel= 0xfff3
	; -> Baudrate 28846
	
	; SMOD aktivieren
	MOV PCON, #1000$0000b
	
	; S0REL (S0RELH | S0RELL) einstellen
	MOV S0RELL, #0xf3
	MOV S0RELH, #0xff
	
	; Baudgenerator benutzen
	SETB BD
	
	; ASCII Byte an S0BUF senden
	MOV S0BUF, R7
	
	; Warte auf TI0
	; TI0 ist Bit 1 von S0CON
	wait_for_send:
		JNB TI0, wait_for_send
	
	; Nachrichte wurde gesendet
	; Entferne TI0 Flag
	ANL S0CON, #1111$1101
	
	; -- [TODO] -- ;
	; Jump zu Punktauswahl
	; ------------ ;
	
	NOP
	NOP
	
	END