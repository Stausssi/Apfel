	; -- [Aufgabenstellung] -- ;
	; - Schreiben sie ein Programm zur Berechnung von Apfelmaennchen -- ;
	; - A, B, Px und Nmax sind als Konstanten zu definieren
	; - Die Farbwerte der einzelnen Punkte c sind als ASCII-Zeichen über die serielle Schnittstelle auszugeben
	
$NOMOD51
#include <Reg517a.inc>

	; -- [Definieren der Konstanten] -- ;
	Nmax EQU 10000
	Px EQU 100
		
	; -- A und B sind im Format VVVV VV.NN | NNNN NNNN + i * VVVV VV.NN | NNNN NNNN -- ;
	; Hier wird jeweils der Real- und Imaginaerteil als Integer ohne Kommastelle angegeben
	; Somit enspricht beispielsweise 1,5 dem Definitionswert 1536
	
	; A = 1,5 + 0,5i
	A_re_H EQU 6
	A_re_L EQU 0
	A_im_H EQU 2
	A_im_L EQU 0
		
	; B = 2,25 + i
	B_re_H EQU 5
	B_re_L EQU 0
	B_im_H EQU 4
	B_im_L EQU 0
	
	; -- Definieren von genutzten Speicheradressen -- ;
	; Komplementbildung
	comp_adr EQU 02Ch
		
	; Speicherstellen für Addition von komplexen Zahlen A + B im Format VVVVVV.NN | NNNNNNNN + i * VVVVVV.NN | NNNNNNNN
	//Re(A)
	ADD_A_RE_H EQU 020h
	ADD_A_RE_L EQU 021h
	
	//Im(A)
	ADD_A_IM_H EQU 022h
	ADD_A_IM_L EQU 023h
	
	//Re(B)
	ADD_B_RE_H EQU 024h
	ADD_B_RE_L EQU 025h
	
	//Im(B)
	ADD_B_IM_H EQU 026h
	ADD_B_IM_L EQU 027h
	
	; Abstand zwischen den Punkten
	dist_adr_H EQU 02Dh
	dist_adr_L EQU 02Eh
	
	; -------------------------------------------------- ;
		
		
		
	; -- [Abstand von A und B ausrechnen] -- ;
	; -- Abstand auf der reellen Achse -- ;
	; Abstand ist gegeben durch (-A + B)/Px
	; Der Abstand auf der imaginaeren Achse ist gleichzusetzen
	
	; Komplement von A
	MOV comp_adr, #A_re_H
	LCALL comp
	
	; Schreiben der Speicherstellen
	; Imaginaerteil ist 0
	MOV ADD_A_RE_H, comp_adr
	MOV ADD_A_RE_L, #A_re_L
	MOV ADD_A_IM_H, #0d
	MOV ADD_A_IM_L, #0d
	
	MOV ADD_B_RE_H, #B_re_H
	MOV ADD_B_RE_L, #B_re_L
	MOV ADD_B_IM_H, #0d
	MOV ADD_B_IM_L, #0d
	
	; UP aufrufen, welches 16 Bit zahlen addiert
	LCALL addImAB
	
	; Ergebnis ist in den ersten vier Byte (urspruenglich A)
	; Beachte nur die ersten zwei -> Imaginaerteil irrelevant
	
	; Dividieren durch Px
	; Algorithmus:
	; - Aufteilen in 3 Teile:
	;	- 1. Teil: Divisor left-shift bis erste 1 ganz links angekommen
	;	- 2. Teil: Divisor right-shift und von Dividend abziehen, sofern moeglich
	;	- 3. Teil: Ergebnis abspeichern
	;	- Wiederholen, bis Divisor wieder gleich wie bei Anfang
	
	; Divisor in R3|R2
	MOV R3, #0d
	MOV R2, #Px
	
	; Dividend in R1|R0
	MOV R1, ADD_A_RE_H
	MOV R0, ADD_A_RE_L
	
	; B als Counter
	MOV B, #0d
	div1:
		; B erhoehen
		INC B
		
		; Low-Byte von Divisor in A und left-shift
		MOV A, R2
		RLC A
		MOV R2, A
		
		; High-Byte von Divisor in A und left-shift
		MOV A, R3
		RLC A
		MOV R3, A
		
		; Wiederholen, bis Carry-Flag von High-Byte gesetzt
		; -> Ganz ans Ende "geschoben"
		JNC div1
	
	; Divisor wieder nach und nach right-shift
	div2:
		; Zuerst mit High-Byte von Divisor
		MOV A, R3 
		RRC A
		MOV R3, A
		
		; Dann Low-Byte von Divisor
		MOV A, R2
		RRC A
		MOV R2, A
		
		CLR C
		
		; Erstelle Sicherheitskopie von Dividend, falls Subtraktion fehlschlaegt
		MOV 07h, R1
		MOV 06h, R0
		
		; Low-Byte von Dividend in A
		MOV A,R0
		
		; Subtrahiere Low-Byte von Divisor 
		SUBB A, R2
		MOV R0, A
		
		; Wiederholen fuer High-Byte
		MOV A, R1
		SUBB A, R3
		MOV R1, A
		
		; Testen, ob Subtraktion erfolgreich
		; Ergebnis ist 1, wenn Carry nicht gesetzt
		JNC div3
		
		; Sonst Sicherheitskopie wiederherstellen
		MOV R1, 07h
		MOV R0, 06h
		
		
	div3:
		; Invertiere Carry (Ergebnis 1, falls Carry nicht gesetzt)
		CPL C
		
		; Low-Byte Ergebnis in R4
		MOV A, R4
		
		; Shift mit Carry um Ergebnis direkt in R4 zu speichern
		RLC A
		MOV R4, A 

		; Wiederholen mit High-Byte
		MOV A, R5
		RLC A
		MOV R5, A
		
		; Wiederholen, bis counter 0
		DJNZ B, div2
		
	; Schreiben des Ergebnisses in dist_adr
	MOV dist_adr_H, R5
	MOV dist_adr_L, R4
	
	; -------------------------------------------------- ;
		
		
		
	; -- [Hauptschleife] -- ;
main:
	; Ablauf:
	; - Punkt auswählen
	; - Mandelbrotiteration berechnen
	; - Abbruchbedingungen überprüfen:
	;   Nein? -> Neue Iteration durchführen
	;   Ja? -> Farbwert berechnen (calc_ascii) und ausgeben
	; - Neuen Punkt auswaehlen (oder fertig)
	
	; ....
	
	
	; -- Farbwert berechnen und ausgeben -- ;
	//LJMP calc_ascii
	
	; -------------------------------------------------- ;
		
		
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
		
	
	; -- [Addieren von zwei Komplexen Zahlen A und B] -- ;
addImAB:	
	; Rechnung: (        Re(A)       + i *        Im(A)       ) + (        Re(B)       + i *        Im(B)      )
	; Format:   (VVVVVV.NN |NNNNNNNN + i * VVVVVV.NN |NNNNNNNN) + (VVVVVV.NN |NNNNNNNN + i * VVVVVV.NN |NNNNNNNN)
	
	; Eingabe:  |   020h   |  021h    |   |  022h    |  023h    | |  024h    |  025h    |   |  026h    |  027h    |
	; Konstante:|ADD_A_RE_H|ADD_A_RE_L|   |ADD_A_IM_H|ADD_A_IM_L| |ADD_B_RE_H|ADD_B_RE_L|   |ADD_B_IM_H|ADD_B_IM_L|
	
	;Ausgabe zu Zahl C im gleichen Format in urspruengliche Speicherstellen von A;
	;Registerbelegung: Re(A): R6 | Im(A): R5 | Re(B): R4 | Im(B): R3;
	;Ausgabe: Re(C): R6 | Im(C): R5;
	
	
	//Berechnung A + B
	
	//Realteil
	CLR C // clear carry flag
	
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
	RET
	

	//A^2 berechnen
	
	
	//...........................................................
	
	
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
	// In R1: P1 <= H11 + carry from P2
	// In R2: P2 <= H21 + H12 + L11 + carry from P3 
	// In R3: P3 <= H22 + L21 + L12
	// In R4: P4 <= L22
	
	//Input Werte im Speicher an folgenden festen Speicherstellen:
	
	//--> Speicherstellen 
	
	//(A)
	MOV 028h, #011011$01b //A1
	MOV 029h, #01000010b  //A2
	
	MOV comp_adr, 028h
	
	LCALL comp
	
	MOV 028h, comp_adr
	
	//(B)
	MOV 02Ah, #011010$01b //B1
	MOV 02Bh, #10001011b  //B2
	
	//Berechnung a * b, wobei a, b Festkommazahlen im Format VVVVVV.NNNNNNNNNN sind
	
mult_ab:
	// A2 * B2
	MOV A, 029h // A2
	MOV B, 02Bh // B2
	MUL AB //L22 in A, H22 in B
	
	MOV R4,A //L22
	MOV R3,B //H22
	
	// B2 * A1 
	MOV A, 02Bh // B2
	MOV B, 028h // A1
	MUL AB //L21 in A, H21 in B
	
	MOV R2, B // H21 in R2
	
	// P3 + L21(in A)
	ADD A, R3
	MOV R3, A // write back
	
	//B1 * A2
	MOV A, 02Ah // B1
	MOV B, 029h // A2
	MUL AB //L12 in A, H12 in B
	
	CLR C // clear carry
	ADD A, R3 //add L12 to result in R3
	MOV R3, A // write back to R3
	
	//Add H12 to R2 plus carry
	MOV A, B
	ADDC A, R2
	MOV R2, A
	CLR C // clear carry
	
	//B1 * A1
	MOV A, 02Ah // B1
	MOV B, 028h // A1
	MUL AB //L11 in A, H11 in B
	
	// add L11 to result in R2, write back
	CLR C
	ADD A, R2
	MOV R2, A
	
	//Add carry to H11
	MOV A, B
	ADDC A, #0
	MOV R1, A

	;Fallunterscheidung: 
	; 1) beide Zahlen positiv: normale Multiplikation
	; 2) A positiv, B negativ --> comp(B), Ergebnis komplementieren
	; 3) B positiv, A negativ --> comp(A), Ergebnis komplementieren
	; 4) B negativ, A negativ --> comp(A), Ergebnis nicht komplementieren
	
	;Testen ob 6Bit Zweierkomplementzahl vor dem Komma positiv ist:
	; Das zu betrachtende Byte hat die Form VVVVVV.XX. 
	; Wenn VVVVVV > 100000d bzw. wenn das HSB gesetzt ist, dann handelt es sich
	; um eine negativ Zweierkomplementzahl
	
	

	; -------------------------------------------------- ;
	
	
	
	; -- [Berechnen des Komplements] -- ;
comp:
	; Die Zahl hat hier das Format VVVVVV.NN
	; - Bilder 2erKomplement von VVVVVV
	; - Die Nachkommastellen bleiben unverändert
	; Das Zweierkomplement steht danach wieder in comp_adr
	
	; Kopiere die Zahl in A
	MOV A, comp_adr
	
	; Trenne alles außer Nackommastellen ab
	ANL comp_adr, #00000011b
	
	; Rotiere Akk zwei mal nach Rechts
	RR A
	RR A
	
	; Trenne alte Nachkommastellen ab
	ANL A, #00111111b
	
	; Bilde das Zweierkomplement
	CPL A
	ADD A, #1d
	
	; Rotiere zwei mal nach links, um die Form VVVVVV.NN wiederherzustellen
	RL A
	RL A
	ANL A, #11111100b
	
	; Fuege unveraenderte Nachkommstellen hinzu
	ADD A , comp_adr
	
	; Zurueckschreiben
	MOV comp_adr, A
	
	; Zurueckspringen
	RET
	 
	; -------------------------------------------------- ;
	
	

	; -- [Berechung von ASCII abhaengig von n] -- ;
calc_ascii:
	; n liegt in Register R7
	MOV A, R7

	; Zuerst ueberpruefen, ob n = Nmax gilt
	SUBB A, #Nmax
	CLR C
	
	; ACC = 0, wenn n = Nmax
	JZ set_ascii_nmax 
	
	; ACC != 0
	; -> Mod 8 rechnen
	MOV A, R7
	MOV B, #8d
	DIV AB
	
	; A enthaelt Ergebnis der Division, B den Rest -> Rest in A schreiben
	MOV A, B
	
	; Nun wird der für den gegebenen Rest das jeweilige UP aufgerufen, welches das ASCII-codierte Zeichen in R7 schreibt
	; und danach das UP aufruft, welches das ASCII-Zeichen auf die serielle Schnittstelle schreibt
	
	; Rest 0
	JZ set_ascii_mod0
	
	; Rest > 0
	SUBB A, #1
	JZ set_ascii_mod1
	
	; Rest > 1
	SUBB A, #1
	JZ set_ascii_mod2
	
	; Rest > 2
	SUBB A, #1
	JZ set_ascii_mod3
	
	; Rest > 3
	SUBB A, #1
	JZ set_ascii_mod4
	
	; Rest > 4
	SUBB A, #1
	JZ set_ascii_mod5
	
	; Rest > 5
	SUBB A, #1
	JZ set_ascii_mod6
	
	; Rest > 6
	SUBB A, #1
	JZ set_ascii_mod7
	
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
	
	; -- Senden des ASCII Byte -- ;
	; Zeichen liegt in R7
	MOV S0BUF, R7
	
	; Warte auf TI0
	wait_for_send:
		JNB TI0, wait_for_send
	
	; Nachrichte wurde gesendet
	; Entferne TI0 Flag
	ANL S0CON, #1111$1101
	
	; -- Springe zu Hauptprogramm -- ;
	LJMP main
	
	; -------------------------------------------------- ;
	
	
	
	NOP
	NOP
	
	END