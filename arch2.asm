;=============================================================================;
;                                                                             ;
; Plik           : arch_02.asm                                                ;
; Format         : COM                                                        ;
; Cwiczenie      : Napisaæ program, który konwertowaæ bêdzie dwie liczby	  ;
;				   ca³kowite z przedzia³u [-32768..32767] z postaci ASCII do  ;
;				   postaci obliczeniowej w kodzie U2, dodawaæ je do siebie,   ;
;				   a otrzymany wynik wyœwietlaæ na ekranie.					  ;
; Autorzy        : Emilia Masiak, Martyna Plutowska, 7.1, piatek, 12:15		  ;
; Data zaliczenia: 14.04.2025                                                 ;
; Cel            : Zapoznanie siê z zasadami reprezentacji liczb w kodzie U2  ;
;				   i znaków w kodzie ASCII.                                   ;
;                                                                             ;
;=============================================================================;

                .MODEL  TINY 

Kod             SEGMENT

                ORG    100h 
                ASSUME  CS:Kod, DS:Kod, SS:Kod 

Start:
                jmp    Poczatek 
			
Napis           DB      "Podaj liczbe z zakresu (-32768; 32767): $"
NapisError      DB      "Liczba z poza zakresu!! Koncze program$"
NapisOutOfRange DB		"Wynik poza zakresem signed 16 bit int! Koncze program$"
; ---- ASCII inputs
input1			DB		7		; max chars the user can input + CR 
				DB		?		; acctual number of chars that user entered (filled by DOS)
				DB		6 DUP(0); 6 bytes for the chars
input2			DB		7
				DB		?
				DB		6 DUP(0)
; ---- ASCII inputs converted to int
liczba1			DW		?
liczba2			DW		?

; ---- result in int
wynik			DW		?
; ---- result in ASCII
output			DW		6 DUP(0), "$"
; ---- Helper flag to convert numbers to U2
bIsNeg			DB		0

big				DD		?



Poczatek:
; -------- GET THE INPUT
; 		-- First input
				; print text asking for a number
				mov ah, 09h
                mov dx, OFFSET Napis
                int 21h
				
				; get the first input
				mov ah, 0Ah
				lea dx, input1		; put addres of input1 to dx
				int 21h
				call PrintNewLine	; add new line so the next text will be on new line

				mov cl, input1+1 	; the number of digits the user entered
				xor ax, ax		 	; zero out the ax
				lea si, input1+2 	; addres of the first character
				
				call AsciiToInt 	; convert ascii to number and convert to U2 (ax and wynik will have the output)
				
				mov liczba1, ax 	; save the converted number to liczba1 variable
				mov wynik, 0		; zero out the wynik

; 		-- Second input
				; print text asking for second number
				mov ah, 09h
                mov dx, OFFSET Napis
                int 21h
				
				; get the second input
				mov ah, 0Ah
				lea dx, input2
				int 21h
				call PrintNewLine ; add new line after the text
				
				mov cl, input2+1
				xor ax, ax
				lea si, input2+2
				
				call AsciiToInt ; ax and wynik will have the output
				
				mov liczba2, ax
				mov wynik, 0

; -------- ADD THE NUMBERS
				add liczba1, ax ; liczba1 + liczba2 (result in liczba1)
				jo HandleOverflow
				mov ax, liczba1 ; we can't directly move from one var to another, so we have to use a register
				mov wynik, ax

; -------- PRINT THE RESULT	
; 		-- Print minus sign if the result is negative		
				test ax, ax	  ; performs bitwise AND operation (ax = wynik), sets the SF (sign flag) for the jump, the result is discarded
				
				jns NotSigned ; jump if not signed (if the SF is not set)
				
				; negate back the number for ascii conversion (converts the number from U2 to natural code)
				neg wynik
				;print the minus sign (02h prints one character and doesn't expect $ at the end)
				mov dl, '-'
				mov ah, 02h
				int 21h

	NotSigned:
; 		-- Prepare registers for the conversion to ascii	
				
				mov ax, wynik 	; wynik will be used in the CountDigits func so we pass it as ax
				call CountDigits; count how many digits does the result have (result in cx)
				
				mov ax, wynik
				lea si, wynik	; move the addres of the result to the si
				xor ax, ax
				mov ax, [si]	; move the result to ax

; 		-- Convert the result back to ASCII
	IntToAscii:
				xor dx, dx	; zero out dx before division
				mov bx, 10
				div bx		; ax (result from the previous division) / 10	
				; ax - result (will be use in next iteration)
				; dx - remainder (the current number)	
				add dx, '0'	; add 30h to convert number to ASCII
				
				mov di, cx	; we can only use si and di to work with memory so we put the current index to di
				mov byte ptr [output + di - 1], dl ; put the converted digit to the iteration number-nth byte in output variable 
										  ; -1 bc byte count starts with 0
				loop IntToAscii ; decrease cx and go to the next iteration
				
; 		-- Print the converted number						
				mov ah, 09h	
                mov dx, OFFSET output
                int 21h
			
; -------- THE END
				jmp Koniec ; we have to jump here to omit the functions

; -------- OVERFLOW HANDLING
HandleOverflow:
				; handle 
				mov ax, liczba1
				cwd			; sign-extend into DX:AX
				
				mov bx, dx	; Save high word of first number
				mov cx, ax	; Save low word of first number
				
				mov ax, liczba2
				cwd			; sign-extend into DX:AX
				
				add cx, ax
				adc bx, dx 
				
				; result in BX:CX
				;mov word ptr [big], cx       ; store low word first (little endian)
				;mov word ptr [big+2], bx     ; store high word
				
				; convert 32 result to ascii
				mov ah, 09h
                mov dx, OFFSET NapisOutOfRange
                int 21h
			
				jmp Koniec
		
; ---------------- FUNKCJE
PrintNewLine PROC
				; new line
				mov ah, 02h	; 02h prints one character and doesn't expect $ at the end
				mov dl, 0Dh ; Carriage Return (CR)
				int 21h
				
				mov ah, 02h
				mov dl, 0Ah ; Line Feed (LF)
				int 21h
				ret
PrintNewLine ENDP

; ---------------- @TODO comment this function
AsciiToInt PROC
				mov bIsNeg, 0
				mov bl, [si]
				cmp bl, '-'
				jne NotNegative
				inc si
				dec cl
				mov bIsNeg, 1
	NotNegative:
	petla:
				mov bl, [si]
				sub bl, '0'
				
				mov ax, 10
				mul wynik
				add ax, bx
				mov wynik, ax
				
				inc si
				
				loop petla
				
				cmp bIsNeg, 1
				jne NotNegative2
				
				; Negative max = 32768
				cmp ax, 32769
				jae PrintError
				
				neg wynik		; converts number from natural code to the U2 (negates the number and adds 1)
				mov ax, wynik
				ret
	NotNegative2:	
				; Positive max = 32767
				cmp ax, 32768
				jae PrintError
	
				ret
AsciiToInt ENDP


CountDigits PROC
				; ax = wynik
				xor cx, cx
				mov bx, 10
CountLoop:
				inc cx
				xor dx, dx
				div bx ; ax / 10 = ax
				cmp ax, 0
				jne CountLoop
				ret
CountDigits ENDP


PrintError PROC
				mov ah, 09h
                mov dx, OFFSET NapisError
                int 21h
				jmp Koniec
PrintError ENDP



; ---------------- KONIEC (END THE PROGRAM)
Koniec:         mov ax, 4C00h
                int 21h

Kod             ENDS
                END Start