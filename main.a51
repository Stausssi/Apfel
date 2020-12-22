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
	A_RE_H EQU 000001$10b
	A_RE_L EQU 00000000b
	A_IM_H EQU 000000$10b
	A_IM_L EQU 00000000b
		
	; B = 2,25 + i
	B_RE_H EQU 000010$01b
	B_RE_L EQU 00000000b
	B_IM_H EQU 000001$00b
	B_IM_L EQU 00000000b
	
	; -- [Definieren von genutzten Speicheradressen] -- ;
	; -- Speicherstellen für Addition von komplexen Zahlen A + B im Format VVVVVV.NN | NNNNNNNN + i * VVVVVV.NN | NNNNNNNN -- ;
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
		
	; -- Speicherstellen fuer die Addition zweier 16Bit Zahlen A und B im obigen Format -- ;
	ADD_A_H EQU 028h
	ADD_A_L EQU 029h
	
	ADD_B_H EQU 02Ah
	ADD_B_L EQU 02Bh
		
	; -- Speicherstellen fuer Multiplikation von zwei Zahlen a, b im Format VVVVVV.NN | NNNNNNNN -- ;
	MUL_A_H EQU 02Ch //A1 --> High
	MUL_A_L EQU 02Dh //A2 --> Low
	
	MUL_B_H EQU 02Eh //B1 --> High
	MUL_B_L EQU 02Fh //B2 --> Low
		
	; -- Speicherstellen fuer quadrieren einer komplexen Zahl im Format (a + b*i) -- ;
	QUAD_A_H EQU 030h // --> High
	QUAD_A_L EQU 031h // --> Low
	
	QUAD_B_H EQU 032h // --> High
	QUAD_B_L EQU 033h // --> Low
		
	; -- Speicherstellen fuer Division A/B von  zwei 16Bit Zahlen im obigen Format -- ;
	DIV_A_H EQU 034h
	DIV_A_L EQU 035h
		
	DIV_B_H EQU 036h
	DIV_B_L EQU 037h
		
	; -- Komplementbildung -- ;
	comp_adr EQU 038h
	comp_entire_H EQU 039h
	comp_entire_L EQU 03Ah
	
	; -- Abstand zwischen den Punkten -- ;
	dist_adr_H EQU 03Bh
	dist_adr_L EQU 03Ch
		
	; -- Schleifenzaehler -- ;
	loop_outer EQU 03Dh
	loop_inner EQU 03Eh
		
	; -- temporärer Punkt c -- ;
	C_RE_H EQU 040h
	C_RE_L EQU 041h
	
	C_IM_H EQU 042h
	C_IM_L EQU 043h
	
	; -------------------------------------------------- ;
		
		
		
	; -- [Abstand von A und B ausrechnen] -- ;
	; Es muss nur der Abstand auf der reellen Achse auszurechnen
	; Abstand ist gegeben durch (-A + B)/Px
	; Der Abstand auf der imaginaeren Achse ist gleichzusetzen
	
	; -- Komplement von A -- ;
	MOV comp_adr, #A_RE_H
	LCALL comp
	
	; -- Addition -- ;
	; Schreiben der Speicherstellen fuer Addition
	; Imaginaerteil ist 0
	MOV ADD_A_H, comp_adr
	MOV ADD_A_L, #A_RE_L
	
	MOV ADD_B_H, #B_RE_H
	MOV ADD_B_L, #B_RE_L

	; UP aufrufen, welches 16 Bit zahlen addiert
	LCALL add16
	
	; Ergebnis ist in den ersten vier Byte (urspruenglich A)
	; Beachte nur die ersten zwei -> Imaginaerteil irrelevant
	
	MOV DIV_A_H, ADD_A_H
	MOV DIV_A_L, ADD_A_L
	
	MOV DIV_B_H, #0d
	MOV DIV_B_L, #Px
	
	LCALL div16
	
	; -- Schreiben des Ergebnisses in dist_adr -- ;
	MOV dist_adr_H, DIV_A_H
	MOV dist_adr_L, DIV_A_L	
		
	; -- [Hauptschleife] -- ;
main:
	; Ablauf:
	
	;innerer Schleifencounter initialisieren --> eine Reihe;
	MOV loop_outer, #Px
	 
	;äußere Schleifencounter initialisieren ; --> Anzahl der Reihen
	 
	MOV comp_adr, #A_IM_H
	LCALL comp
	
	; -- Addition -- ;
	; Schreiben der Speicherstellen fuer Addition
	; Imaginaerteil ist 0
	MOV ADD_A_H, comp_adr
	MOV ADD_A_L, #A_IM_L
	
	MOV ADD_B_H, #B_IM_H
	MOV ADD_B_L, #B_IM_L

	; UP aufrufen, welches 16 Bit zahlen addiert
	LCALL add16
	
	; Ergebnis ist in den ersten vier Byte (urspruenglich A)
	; Beachte nur die ersten zwei -> Imaginaerteil irrelevant
	
	MOV DIV_A_H, ADD_A_H
	MOV DIV_A_L, ADD_A_L
	
	MOV DIV_B_H, dist_adr_H
	MOV DIV_B_L, dist_adr_L
	
	LCALL div16
	
	MOV A, DIV_A_H
	ANL A, #11111100b
	RR A
	RR A
	INC A
	MOV loop_outer, A
	
	; Anfangspunkt fuer C;
	
	MOV C_RE_H, A_RE_H
	MOV C_RE_L, A_RE_L
	
	MOV C_IM_H, B_IM_H
	MOV C_IM_L, B_IM_L

	outer_loop:
	
		;Counter zurücksetzen
		MOV loop_inner, #Px
		INC loop_inner
		
		inner_loop:
		
			mandelbrot:
			
				; - Mandelbrotiteration berechnen
				; - Abbruchbedingungen überprüfen:
				;   Nein? -> Neue Iteration durchführen
				;   Ja? -> Farbwert berechnen (calc_ascii) und ausgeben
			
			; C + Abstand;
		
			DJNZ loop_inner, inner_loop
		
		;C + imaginaerer Abstand
		
		DJNZ loop_outer, outer_loop
	
	
	; - Neuen Punkt auswaehlen (oder fertig)
	
	; ....
;	NOP
;	MOV QUAD_A_H , #000010$00b
;	MOV QUAD_A_L , #00000000b
;	
;	MOV QUAD_B_H , #100010$00b
;	MOV QUAD_B_L , #00000000b
;	
;	LCALL quad
;	
;	NOP

	MOV ADD_B_RE_H, #111110$01b
	MOV ADD_B_RE_L, #00000000b
			  
	MOV ADD_A_RE_H, #111101$10b
	MOV ADD_A_RE_L, #00000000b
	
	
	MOV ADD_A_IM_H, #111110$01b
	MOV ADD_A_IM_L, #00000000b
			
	MOV ADD_B_IM_H, #000011$10b
	MOV ADD_B_IM_L, #00000000b
	
	LCALL addImAB
	
	NOP
	
	; -- Farbwert berechnen und ausgeben -- ;
	LCALL calc_ascii
	
	; -------------------------------------------------- ;
	
	; -- Division -- ;
div16:
	; Dividieren durch Px
	; Algorithmus:
	; - Aufteilen in 3 Teile:
	;	- 1. Teil: Divisor left-shift bis erste 1 ganz links angekommen
	;	- 2. Teil: Divisor right-shift und von Dividend abziehen, sofern moeglich
	;	- 3. Teil: Ergebnis abspeichern
	;	- Wiederholen, bis Divisor wieder gleich wie bei Anfang
	
	; Divisor
	MOV R3, DIV_B_H
	MOV R2, DIV_B_L
	
	; Dividend
	MOV R1, DIV_A_H
	MOV R0, DIV_A_L
	
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

	; Ergebnis zurückschreiben
	MOV DIV_A_H, R1
	MOV DIV_A_L, R0
	
	; -- Zuruecksetzen der Register -- ;
	MOV R0, #0d
	MOV R1, #0d
	MOV R2, #0d
	MOV R3, #0d
	MOV R4, #0d
	MOV R5, #0d
	
	RET
	
	; -------------------------------------------------- ;		
		

	; -- [Addieren von zwei Komplexen Zahlen A und B] -- ;
addImAB:
	; Rechnung: (        Re(A)       + i *        Im(A)       ) + (        Re(B)       + i *        Im(B)      )
	; Format:   (VVVVVV.NN |NNNNNNNN + i * VVVVVV.NN |NNNNNNNN) + (VVVVVV.NN |NNNNNNNN + i * VVVVVV.NN |NNNNNNNN)
	
	; Eingabe:  |   020h   |  021h    |   |  022h    |  023h    | |  024h    |  025h    |   |  026h    |  027h    |
	; Konstante:|ADD_A_RE_H|ADD_A_RE_L|   |ADD_A_IM_H|ADD_A_IM_L| |ADD_B_RE_H|ADD_B_RE_L|   |ADD_B_IM_H|ADD_B_IM_L|
	
	;Ausgabe zu Zahl C im gleichen Format in urspruengliche Speicherstellen von A;
	
	//Berechnung A + B
	
	; Zuerst Realteil addieren
	MOV ADD_A_H, ADD_A_RE_H
	MOV ADD_A_L, ADD_A_RE_L

	MOV ADD_B_H, ADD_B_RE_H
	MOV ADD_B_L, ADD_B_RE_L
	
	LCALL add16
	
	MOV ADD_A_RE_H, ADD_A_H
	MOV ADD_A_RE_L, ADD_A_L
	
	
	; Dann imaginaer addieren
	MOV ADD_A_H, ADD_A_IM_H
	MOV ADD_A_L, ADD_A_IM_L
					   
	MOV ADD_B_H, ADD_B_IM_H
	MOV ADD_B_L, ADD_B_IM_L
	
	LCALL add16
	
	MOV ADD_A_IM_H, ADD_A_H
	MOV ADD_A_IM_L, ADD_A_L
	
	RET

	; -------------------------------------------------- ;
	
	
	
	; -- [Addition von zwei 16 Bit Zahlen] -- ;
add16:
	//Check, ob Zahlen negativ sind, wenn ja --> invertiere Vorkammastellenbits und dann ganze Zahl
	;Abtrennung des Highbytes von A1;
	MOV A, ADD_A_H
	RL A //High Byte ist jetzt low Byte
	ANL A, #00000001b //entferne der restlichen bits
	MOV R4, A // zwischenspeichern
	
	;Abtrennung des Highbytes von B1;
	MOV A, ADD_B_H
	RL A //High Byte ist jetzt low Byte
	ANL A, #00000001b //entferne der restlichen bits
	MOV R5, A // zwischenspeichern
	
	; R4 enthaelt ob A neg
	; R5 enthaelt ob B neg
	MOV A, R4
	JNZ add_A_neg
	
	; A pos, B neg
	MOV A, R5
	JNZ add_B_neg
	
	; Sowohl A, als auch B pos
	LJMP add_calc
	
	; Bilde das 2erKomplement der gesamten Zahl
	add_A_neg:
		; Zahl zurueck in normale, pos Darstellung
		MOV comp_adr, ADD_A_H
		LCALL comp
		MOV ADD_A_H, comp_adr
		
		; Schauen, ob B auch neg
		; Falls ja: Kein komplett Komplement notwendig
		MOV A, R5
		JNZ add_A_B_neg
		
		; A neg, B pos
		; Komplette Zahl (auch Nachkommastellen) flippen
		MOV comp_entire_H, ADD_A_H
		MOV comp_entire_L, ADD_A_L
		
		LCALL comp_entire
		
		MOV ADD_A_H, comp_entire_H
		MOV ADD_A_L, comp_entire_L
		
		LJMP add_calc
		
	add_A_B_neg:
		; B zurueck in normale, pos Darstellung
		MOV comp_adr, ADD_B_H
		LCALL comp
		MOV ADD_B_H, comp_adr
		
		LJMP add_calc
		
	add_B_neg:
		; Zahl zurueck in pos Darstellung
		MOV comp_adr, ADD_B_H
		LCALL comp
		
		; Komplette Zahl (auch Nachkommastellen) flippen
		MOV comp_entire_H, comp_adr
		MOV comp_entire_L, ADD_B_L
		
		LCALL comp_entire
		
		MOV ADD_B_H, comp_entire_H
		MOV ADD_B_L, comp_entire_L
	
	add_calc:
		CLR C // clear carry flag
			
		MOV R6, ADD_A_L // A LSB
		MOV A, R6
		ADD A, ADD_B_L  // B LSB
		MOV ADD_A_L, A // zurück nach LSB von A
		
		MOV R6, ADD_A_H // A MSB
		MOV A, R6
		ADDC A, ADD_B_H // B MSB
		MOV ADD_A_H, A // zurück nach MSB von A

		; Schauen, ob beide negativ waren
		MOV A, R4
		ANL A, R5
		JNZ add_flip
		
		RET
		
		; Flip Ergebnis
		add_flip:
			MOV comp_adr, ADD_A_H
			LCALL comp
			MOV ADD_A_H, comp_adr
			
			RET
	
	; -------------------------------------------------- ;
	
	
	
	
	; -- [Quadrierung einer imaginaeren Zahl] -- ;
	; Formel: (a + bi)^2 = a^2 - b^2 + 2abi
quad:
	// a^2
	MOV MUL_A_H, QUAD_A_H
	MOV MUL_B_H, QUAD_A_H
	
	MOV MUL_A_L, QUAD_A_L
	MOV MUL_B_L, QUAD_A_L
	
	LCALL mult
	
	MOV ADD_A_RE_H, MUL_A_H
	MOV ADD_A_RE_L, MUL_A_L
	
	MOV ADD_A_IM_H, #0d
	MOV ADD_A_IM_L, #0d
	
	//b^2
	
	MOV MUL_A_H, QUAD_B_H
	MOV MUL_B_H, QUAD_B_H
					  
	MOV MUL_A_L, QUAD_B_L
	MOV MUL_B_L, QUAD_B_L
	
	LCALL mult
	
	// comp b^2
	MOV comp_entire_H, MUL_A_H
	MOV comp_entire_L, MUL_A_L
	
	LCALL comp_entire
	
	MOV ADD_B_RE_H, comp_entire_H
	MOV ADD_B_RE_L, comp_entire_L
	
	MOV ADD_B_IM_H, #0d
	MOV ADD_B_IM_L, #0d
	
	//a^2 - b^2
	
	LCALL addImAB // Ergebnis in ADD_A_RE_H/ADD_A_RE_L 
	
	//Im: 2 * a * b
	
	MOV MUL_A_H, QUAD_A_H // 2 * a
	MOV MUL_A_L, QUAD_A_L
	
	MOV MUL_B_H, #000010$00b // entspricht der 2.0
	MOV MUL_B_L, #0b
	
	LCALL mult
	
	MOV MUL_B_H, QUAD_B_H //Ergebnis * b
	MOV MUL_B_L, QUAD_B_L
	
	LCALL mult
	
	//write back
	MOV QUAD_B_H, MUL_A_H
	MOV QUAD_B_L, MUL_A_L
	
	MOV QUAD_A_H, ADD_A_RE_H
	MOV QUAD_A_L, ADD_A_RE_L
	
	RET

	
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
	//
	//Die Zahlen signalisieren, welche Werte multipliziert wurden. z.B. L21: Lowbyte von B2 * A1
	//Dabei gilt:
	//
	// In R1: P1 <= H11 + carry from P2
	// In R2: P2 <= H21 + H12 + L11 + carry from P3 
	// In R3: P3 <= H22 + L21 + L12
	// In R4: P4 <= L22
	
	//Input Werte im Speicher an folgenden festen Speicherstellen:

	
	//Berechnung a * b, wobei a, b Festkommazahlen im Format VVVVVV.NNNNNNNNNN sind
	//Ergebnisse an Speicherstellen von a
	
mult:

	;Fallunterscheidung: 
	; 1) beide Zahlen positiv: normale Multiplikation
	; 2) A positiv, B negativ --> comp(B), Ergebnis komplementieren
	; 3) B positiv, A negativ --> comp(A), Ergebnis komplementieren
	; 4) B negativ, A negativ --> comp(A), Ergebnis nicht komplementieren
	
	;Testen ob 6Bit Zweierkomplementzahl vor dem Komma positiv ist:
	; Das zu betrachtende Byte hat die Form VVVVVV.XX. 
	; Wenn VVVVVV > 100000d bzw. wenn das HSB gesetzt ist, dann handelt es sich
	; um eine negative Zweierkomplementzahl
	
	;Abtrennung des Highbytes von A1;
	MOV A, MUL_A_H
	RL A //High Byte ist jetzt low Byte
	ANL A, #00000001b //entferne der restlichen bits
	MOV R5, A // zwischenspeichern
	
	;Abtrennung des Highbytes von B1;
	MOV A, MUL_B_H
	RL A //High Byte ist jetzt low Byte
	ANL A, #00000001b //entferne der restlichen bits
	MOV R6, A // zwischenspeichern
	
	;Teste das Vorzeichen von A;
	MOV A, R5
	JNZ mult_A_neg
	
	;Teste das Vorzeichen von B;
	MOV A, R6
	JNZ mult_B_neg
	
	LJMP calc
	
	mult_A_neg:
		//invert A
		MOV comp_adr, MUL_A_H
		LCALL comp
		MOV MUL_A_H, comp_adr
		
		MOV A, R6
		JNZ mult_A_neg_B_neg
		LJMP calc
	
	mult_B_neg:
		//Invert B
		
		MOV comp_adr, MUL_B_H
		LCALL comp
		MOV MUL_B_H, comp_adr
		
		LJMP calc

	mult_A_neg_B_neg:
		//Invert B
		
		MOV comp_adr, MUL_B_H
		LCALL comp
		MOV MUL_B_H, comp_adr
	

	calc:// A2 * B2
		MOV A, MUL_A_L // A2
		MOV B, MUL_B_L // B2
		MUL AB //L22 in A, H22 in B
		
		MOV R4,A //L22
		MOV R3,B //H22
		
		// B2 * A1 
		MOV A, MUL_B_L // B2
		MOV B, MUL_A_H // A1
		MUL AB //L21 in A, H21 in B
		
		MOV R2, B // H21 in R2
		
		// P3 + L21(in A)
		ADD A, R3
		MOV R3, A // write back
		
		//B1 * A2
		MOV A, MUL_B_H // B1
		MOV B, MUL_A_L // A2
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
		MOV A, MUL_B_H // B1
		MOV B, MUL_A_H // A1
		MUL AB //L11 in A, H11 in B
		
		// add L11 to result in R2, write back
		CLR C
		ADD A, R2
		MOV R2, A
		
		//Add carry to H11
		MOV A, B
		ADDC A, #0
		MOV R1, A
		
		;Zurückbringen in ursprüngliche Form durch entfernen der hinteren 10 Nachkommastellen und der ersten 6 Vorkommastellen
		;und rotieren um zwei;
		
		MOV B, #2d
		rotate_r2r:	
			MOV A, R2
			RRC A
			MOV R2, A
			MOV A, R3
			RRC A
			MOV R3, A 
			DJNZ B, rotate_r2r
		
		;write back to original Position of A;
		MOV MUL_A_H, R2
		MOV MUL_A_L, R3
		
		;Wenn eine negative Zahl mit positiver multipliziert wurde, flippe Ergebnis;
		
		MOV A, R6
		XRL A, R5
		JNZ flipResult
		RET
		
	flipResult:
		MOV comp_adr, MUL_A_H
		LCALL comp
		MOV MUL_A_H, comp_adr
		RET

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
	
	
	
	; -- [Berechnung des Komplements der gesamten 16Bit Zahl] -- ;
comp_entire:
	MOV A, comp_entire_L
	CPL A
	ADD A, #1d
	MOV comp_entire_L, A
	
	MOV A, comp_entire_H
	CPL A
	ADDC A, #0d
	MOV comp_entire_H, A
	
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
	
	; -------------------------------------------------- ;
	
	
	
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
	
	; -- Springe zurueck zum Hauptprogramm -- ;
	RET
	
	; -------------------------------------------------- ;
	
	
	
	END