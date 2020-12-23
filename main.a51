	; -- [Aufgabenstellung] -- ;
	; - Schreiben sie ein Programm zur Berechnung von Apfelmaennchen -- ;
	; - A, B, Px und Nmax sind als Konstanten zu definieren
	; - Die Farbwerte der einzelnen Punkte c sind als ASCII-Zeichen über die serielle Schnittstelle auszugeben
	
$NOMOD51
#include <Reg517a.inc>

	; -- [Definieren der Konstanten] -- ;
	Nmax EQU 20
	Px EQU 20
		
	; -- A und B sind im Format VVVV VV.NN | NNNN NNNN + i * VVVV VV.NN | NNNN NNNN -- ;
	; Hier wird jeweils der Real- und Imaginaerteil als Integer ohne Kommastelle angegeben
	; Somit enspricht beispielsweise 1,5 dem Definitionswert 1536
	
	; A = -2,25 - 1,5i
	A_RE_H EQU 111110$01b
	A_RE_L EQU 00000000b
	A_IM_H EQU 111111$10b
	A_IM_L EQU 00000000b
		
	; B = 1,75 + 1,5i
	B_RE_H EQU 000001$11b
	B_RE_L EQU 00000000b
	B_IM_H EQU 000001$10b
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
		
	; -- Speicherstellen fuer mul16iplikation von zwei Zahlen a, b im Format VVVVVV.NN | NNNNNNNN -- ;
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
	comp_H EQU 038h
	comp_L EQU 039h
	
	; -- Abstand zwischen den Punkten -- ;
	dist_adr_H EQU 03Ah
	dist_adr_L EQU 03Bh
		
	; -- Schleifenzaehler -- ;
	loop_outer EQU 03Ch
	loop_inner EQU 03Dh
		
	; -- Temporärer Punkt c -- ;
	C_RE_H EQU 03Eh
	C_RE_L EQU 03Fh
	
	C_IM_H EQU 040h
	C_IM_L EQU 041h
		
	; -- Mandelbrot-Folge -- ;
	Z_RE_H EQU 042h
	Z_RE_L EQU 043h
		
	Z_IM_H EQU 044h
	Z_IM_L EQU 045h
		
	; -------------------------------------------------- ;
		
		
		
	; -- [Abstand von A und B ausrechnen] -- ;
	; Es muss nur der Abstand auf der reellen Achse auszurechnen
	; Abstand ist gegeben durch (-A + B)/Px
	; Der Abstand auf der imaginaeren Achse ist gleichzusetzen
	
	; -- Komplement von A -- ;
	MOV comp_H, #A_RE_H
	MOV comp_L, #A_RE_L
	
	LCALL comp
	
	; -- Addition -- ;
	; Schreiben der Speicherstellen fuer Addition
	; Imaginaerteil ist 0
	MOV ADD_A_H, comp_H
	MOV ADD_A_L, comp_L
	
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
	
	MOV dist_adr_H, #000000$00b
	MOV dist_adr_L, #10011001b
	
	; -------------------------------------------------- ;
	
	
	
	; -- [Hauptschleife] -- ;
main:

	; -- Testing -- ;
	; - Addition			[X]
	; - Multiplikation		[X]
	; - Division 			[ ]
	; - Quadrieren			[X]
	MOV QUAD_A_H, #000000$10b
	MOV QUAD_A_L, #00000000b
	
	MOV QUAD_B_H, #111111$11b
	MOV QUAD_B_L, #00000000b
	
	LCALL quad
	
	;LJMP finish
	; ------------- ;
	
	; Ablauf:
	
	; innerer Schleifencounter initialisieren --> eine Reihe
	MOV loop_outer, #Px
	 
	; aeußere Schleifencounter initialisieren --> Anzahl der Reihen
	MOV comp_H, #A_IM_H
	MOV comp_L, #A_IM_L
	
	LCALL comp
	
	; Berechnen des Abstands auf der imaginaeren Achse
	; Schreiben der Speicherstellen fuer Addition
	MOV ADD_A_H, comp_H
	MOV ADD_A_L, comp_L
	
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
	
	; Anzahl der Punkte ist als Dezimalzahl in dem Low-Byte des Ergebnis der Division
	;MOV loop_outer, DIV_A_L
	MOV loop_outer, #20d
	
	; Anfangspunkt fuer C
	MOV C_RE_H, A_RE_H
	MOV C_RE_L, A_RE_L
	MOV C_IM_H, B_IM_H
	MOV C_IM_L, B_IM_L

	outer_loop:
		; Counter zurücksetzen
		MOV loop_inner, #Px
		
		; C Realteil zuruecksetzen
		; -> Links am Rand anfangen
		MOV C_RE_H, A_RE_H
		MOV C_RE_L, A_RE_L
		
		inner_loop:
			; Zuruecksetzen des Watchdogs
			ORL 0A8h, #0100$0000
			ORL 0B8h, #0100$0000
			
			; Zuruecksetzen des Iterationscounters
			MOV R7, #0d
			
			; Zuruecksetzen von z
			MOV Z_RE_H, #0d
			MOV Z_RE_L, #0d
			MOV Z_IM_H, #0d
			MOV Z_IM_L, #0d
			
			LCALL mandelbrot
			
			; -- Farbwert berechnen und ausgeben -- ;
			LCALL calc_ascii
				
			; C + Abstand auf reeller Achse
			MOV ADD_A_H, C_RE_H
			MOV ADD_A_L, C_RE_L
			MOV ADD_B_H, dist_adr_H
			MOV ADD_B_L, dist_adr_L
			
			LCALL add16
			
			MOV C_RE_H, ADD_A_H
			MOV C_RE_L, ADD_A_L
		
			; loop_inner verringern und zurueckspringen, falls nicht 0
			DJNZ loop_inner, inner_loop
		
		; C + Abstand auf reeller Achse, aber in imaginaerer Richtung
		MOV ADD_A_H, C_IM_H
		MOV ADD_A_L, C_IM_L
		MOV ADD_B_H, dist_adr_H
		MOV ADD_B_L, dist_adr_L
		
		LCALL add16
		
		MOV C_IM_H, ADD_A_H
		MOV C_IM_L, ADD_A_L
		
		; New line in UART ausgeben
		MOV R7, #10d
		LCALL write_ascii
		
		; loop_outer verringern und zurueckspringen, falls nicht 0
		DJNZ loop_outer, outer_loop
	
	LJMP finish
	
	; -------------------------------------------------- ;
	
	
	
	; -- [Berechnung einer Mandelbrot-Iteration -- ;
mandelbrot:
	; Mandelbrotiteration berechnen
	INC R7
	
	; Schauen, ob zn^2 > 4
	; a^2 + b^2 > 4
	; Quadrieren (Multiplizieren mit sich selbst) des Realteils (a) von Z
	MOV MUL_A_H, Z_RE_H
	MOV MUL_A_L, Z_RE_L
	MOV MUL_B_H, Z_RE_H
	MOV MUL_B_L, Z_RE_L
	
	LCALL mul16
	
	; Speichern fuer die folgende Addition
	MOV ADD_A_H, MUL_A_H
	MOV ADD_A_L, MUL_A_L
	
	; Quadrieren des Imaginaerteils (b) von Z
	MOV MUL_A_H, Z_IM_H
	MOV MUL_A_L, Z_IM_L
	MOV MUL_B_H, Z_IM_H
	MOV MUL_B_L, Z_IM_L
	
	LCALL mul16
	
	; Speichern fuer Addition
	MOV ADD_B_H, MUL_A_H
	MOV ADD_B_L, MUL_A_L
	
	; Berechnung von a^2 + b^2
	LCALL add16
	
	; Speichern der Zahl -4 in der Darstellung VVVVVV.NNNNNNNNNN
	MOV ADD_B_H, #111100$00b
	MOV ADD_B_L, #00000000b
	
	; Abziehen von 4 von dem Ergebnis der Addition a^2 + b^2
	LCALL add16
	
	; Schauen, ob Ergebnis der Rechnung positives Vorzeichen hat
	MOV A, ADD_A_H
	ANL A, #1000000b
	JNZ check_over ; Springe, falls negatives Vorzeichen
	
	; Schauen, ob Ergebnis der Rechnung genau 0
	MOV A, ADD_A_H
	ORL A, ADD_A_L
	JNZ mandelbrot_finished ; Springe, falls Ergebnis nicht 0
	
	check_over:
	; Berechnung von zn^2
	MOV QUAD_A_H, Z_RE_H
	MOV QUAD_A_L, Z_RE_L
	
	MOV QUAD_B_H, Z_IM_H
	MOV QUAD_B_L, Z_IM_L
	
	LCALL quad
	
	; Berechnung von zn^2 + c
	; Ergebnis der Quadrierung direkt fuer die Addition weiterverwenden
	MOV ADD_A_RE_H, QUAD_A_H
	MOV ADD_A_RE_L, QUAD_A_L
	MOV ADD_A_IM_H, QUAD_B_H
	MOV ADD_A_IM_L, QUAD_B_L
	
	MOV ADD_B_RE_H, C_RE_H
	MOV ADD_B_RE_L, C_RE_L
	MOV ADD_B_IM_H, C_IM_H
	MOV ADD_B_IM_L, C_IM_L
	
	LCALL addImAB
	
	MOV Z_RE_H, ADD_A_RE_H
	MOV Z_RE_L, ADD_A_RE_L

	MOV Z_IM_H, ADD_A_IM_H
	MOV Z_IM_L, ADD_A_IM_L
	
	CJNE R7, #Nmax, mandelbrot
	
	mandelbrot_finished:
	
	RET
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
		; Nutze Speicheradressen, um einfacher zu kopieren
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
		; Nutze Speicheradressen, um einfacher zu kopieren
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
	MOV DIV_A_H, R5
	MOV DIV_A_L, R4
	
	; -- Zuruecksetzen der Register -- ;
	MOV R0, #0d
	MOV R1, #0d
	MOV R2, #0d
	MOV R3, #0d
	MOV R4, #0d
	MOV R5, #0d
	MOV R6, #0d
	MOV R7, #0d
	
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
	ANL A, R5
	JZ add_calc
	
	;beide negativ, A und B flippen;
	
	;A flippen;
	MOV comp_H, ADD_A_H
	MOV comp_L, ADD_A_L
		
	LCALL comp
	
	MOV ADD_A_H, comp_H
	MOV ADD_A_L, comp_L
	
	;B flippen
	MOV comp_H, ADD_B_H
	MOV comp_L, ADD_B_L
		
	LCALL comp
	
	MOV ADD_B_H, comp_H
	MOV ADD_B_L, comp_L

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
			MOV comp_H, ADD_A_H
			MOV comp_L, ADD_A_L
			
			LCALL comp
			
			MOV ADD_A_H, comp_H
			MOV ADD_A_L, comp_L
			
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
	
	LCALL mul16
	
	MOV ADD_A_RE_H, MUL_A_H
	MOV ADD_A_RE_L, MUL_A_L
	
	MOV ADD_A_IM_H, #0d
	MOV ADD_A_IM_L, #0d
	
	//b^2
	
	MOV MUL_A_H, QUAD_B_H
	MOV MUL_B_H, QUAD_B_H
					  
	MOV MUL_A_L, QUAD_B_L
	MOV MUL_B_L, QUAD_B_L
	
	LCALL mul16
	
	// comp b^2
	MOV comp_H, MUL_A_H
	MOV comp_L, MUL_A_L
	
	LCALL comp
	
	MOV ADD_B_RE_H, comp_H
	MOV ADD_B_RE_L, comp_L
	
	MOV ADD_B_IM_H, #0d
	MOV ADD_B_IM_L, #0d
	
	//a^2 - b^2
	
	LCALL addImAB // Ergebnis in ADD_A_RE_H/ADD_A_RE_L 
	
	//Im: 2 * a * b
	
	MOV MUL_A_H, QUAD_A_H // 2 * a
	MOV MUL_A_L, QUAD_A_L
	
	MOV MUL_B_H, #000010$00b // entspricht der 2.0
	MOV MUL_B_L, #0b
	
	LCALL mul16
	
	MOV MUL_B_H, QUAD_B_H //Ergebnis * b
	MOV MUL_B_L, QUAD_B_L
	
	LCALL mul16
	
	//write back
	MOV QUAD_B_H, MUL_A_H
	MOV QUAD_B_L, MUL_A_L
	
	MOV QUAD_A_H, ADD_A_RE_H
	MOV QUAD_A_L, ADD_A_RE_L
	
	RET

	
	//...........................................................
	
	 
	//multiplikation von zwei 16 Bit Zahlen nach folgendem Schema: 
	
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
	
mul16:

	;Fallunterscheidung: 
	; 1) beide Zahlen positiv: normale mul16iplikation
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
	JNZ mul_A_neg
	
	;Teste das Vorzeichen von B;
	MOV A, R6
	JNZ mul_B_neg
	
	LJMP mul_calc
	
	mul_A_neg:
		//invert A
		MOV comp_H, MUL_A_H
		MOV comp_L, MUL_A_L
		
		LCALL comp
		
		MOV MUL_A_H, comp_H
		MOV MUL_A_L, comp_L
		
		MOV A, R6
		JNZ mul_B_neg
		
		LJMP mul_calc
	
	mul_B_neg:
		//Invert B
		MOV comp_H, MUL_B_H
		MOV comp_L, MUL_B_L
		
		LCALL comp
		
		MOV MUL_B_H, comp_H
		MOV MUL_B_L, comp_L
	

	mul_calc:// A2 * B2
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
		
		;write back to original Position of A
		MOV MUL_A_H, R2
		MOV MUL_A_L, R3
		
		;Wenn eine negative Zahl mit positiver multipliziert wurde, flippe Ergebnis
		MOV A, R6
		XRL A, R5
		JNZ flipResult
		RET
		
	flipResult:
		MOV comp_H, MUL_A_H
		MOV comp_L, MUL_A_L
		
		LCALL comp
		
		MOV MUL_A_H, comp_H
		MOV MUL_A_L, comp_L
		
		RET

	; -------------------------------------------------- ;
	
	
	
	
	; -- [Berechnung des Zweierkomplements der gesamten 16Bit Zahl] -- ;
comp:
	; Invertieren des Low-Bytes
	MOV A, comp_L
	CPL A
	; 1 addieren
	ADD A, #1d
	MOV comp_L, A
	
	; Invertieren des High-Bytes
	; Uebertrag aus Low-Byte addieren
	MOV A, comp_H
	CPL A
	ADDC A, #0d
	MOV comp_H, A
	
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
	; SM0  = 0, 
	; SM1  = 1 -> Mode 1: 8-Bit, var. Baud
	; SM20 = 0 -> RI0 wird aktiviert
	; REN0 = 1 -> Receiver enable
	; TB80 = 0 -> kein 9. Datenbit
	; RB80 = 0 -> Stoppbit
	; TI0  = 0 -> Transmitter interrupt Flag
	; RI0  = 0 -> Receiver interrupt Flag
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
	
finish:
	
	NOP
	NOP
	
	END