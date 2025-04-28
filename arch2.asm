;=============================================================================;
;                                                                             ;
; Plik           : arch_02.asm                                                ;
; Format         : COM                                                        ;
; Cwiczenie      : Napisać program, który konwertować będzie dwie liczby	  ;
;				   całkowite z przedziału [-32768..32767] z postaci ASCII do  ;
;				   postaci obliczeniowej w kodzie U2, dodawać je do siebie,   ;
;				   a otrzymany wynik wyświetlać na ekranie.					  ;
; Autorzy        : Emilia Masiak, Martyna Plutowska, 7.1, piatek, 12:15		  ;
; Data zaliczenia: 14.04.2025                                                 ;
; Cel            : Zapoznanie się z zasadami reprezentacji liczb w kodzie U2  ;
;				   i znaków w kodzie ASCII.                                   ;
;                                                                             ;
;=============================================================================;

                .MODEL  TINY 

Kod             SEGMENT

                ORG    100h 
                ASSUME  CS:Kod, DS:Kod, SS:Kod 

Start:
                jmp    Poczatek
			
Napis			DB      "Podaj liczbe z zakresu (-32768; 32767): $"
NapisError		DB      "Liczba z poza zakresu!! Koncze program$"
NapisWynik		DB		"Wynik dodawania to: $"
NapisNegZero	DB		"-65536$"

; ---- ASCII inputs
input1			DB		7		; max chars the user can input + CR 
				DB		?		; acctual number of chars that user entered (filled by DOS)
				DB		7 DUP(0); 6 bytes for the chars + CR
input2			DB		7
				DB		?
				DB		7 DUP(0)
; ---- ASCII inputs converted to int
liczba1			DW		?
liczba2			DW		?

; ---- result in int
wynik			DW		0

; ---- result in ASCII
output			DB		6 DUP(0), "$"

; ---- Helper flag to convert numbers to U2
bIsNeg			DB		0


Poczatek:
; -------- GET THE INPUT
; 		-- First input
				; print text asking for a number
				mov ah, 09h
                mov dx, OFFSET Napis
                int 21h
				
				; get the first input
				mov ah, 0Ah
				mov dx, OFFSET input1		; put addres of input1 to dx
				int 21h
				
				call PrintNewLine	; add new line so the next text will be on new line

				mov cl, input1+1 	; the number of digits the user entered
				xor ax, ax		 	; zero out the ax
				mov si, OFFSET input1+2 	; addres of the first character
				
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
				mov dx, OFFSET input2
				int 21h
				
				call PrintNewLine ; add new line after the text
				
				mov cl, input2+1
				xor ax, ax
				mov si, OFFSET input2+2
				
				call AsciiToInt ; ax and wynik will have the output
				
				mov liczba2, ax
				mov wynik, 0
				
				mov ah, 09h
                mov dx, OFFSET NapisWynik
                int 21h

; -------- ADD THE NUMBERS
				mov ax, liczba1
				mov bx, liczba2
				add ax, bx ; liczba1 + liczba2 (result in liczba1)
				jo HandleOverflow
				mov wynik, ax
				
; -------- PRINT THE RESULT	

; 		-- Print minus sign if the result is negative	
				mov ax, wynik	
				test ax, ax	  ; performs bitwise AND operation (ax = zmeinna wynik), sets the SF (sign flag) for the jump, the result is discarded
				
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
				mov si, OFFSET wynik	; move the addres of the result to the si
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
				mov ax, liczba1
				cwd			; sign-extend into DX:AX
				
				mov bx, dx	; Save high word of first number
				mov cx, ax	; Save low word of first number
				
				; BX:CX
				
				mov ax, liczba2
				cwd			; sign-extend into DX:AX
				
				; DX:AX
				
				add cx, ax	; add
				adc bx, dx 	; add with a carry
				
				; result is in bx:cx
				
				
				; convert BX:CX to neg if the number is neg
				
				test bx, 8000h ; 8000h = 1000 0000 0000 0000. Only tests the most significant bit (the sign bit)
				jz NotNegative3

				; --- Negative: convert to positive ---
				neg cx
				neg bx
				
				test cx, cx
				;cmp cx, 0
				
				jz NegativeZero
				
				; convert 32 result to ascii
				; Print '-'
				mov ah, 02h
				mov dl, '-'
				int 21h
				
	NotNegative3:
				; result in BX:CX
				mov wynik, cx       ; store low word first (little endian)
				;mov word ptr [big+2], bx     ; store high word

				mov ax, wynik
				call CountDigits	
				
				mov ax, wynik			
					
				jmp IntToAscii
	NegativeZero:	
				mov ah, 09h	
                mov dx, OFFSET NapisNegZero
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


AsciiToInt PROC
				mov bIsNeg, 0	; reset IsNeg flag
				mov bl, [si]	; move first digit to bl
				cmp bl, '-'		; check if the first digit is a minus (if the number is negative)
				jne NotNegative
				inc si			; if number is negative we have to skip the first digit (the minus sign) so we increase si (to get the next digit)
				dec cl			; and decrease cl (number of digits)
				mov bIsNeg, 1	; and set the IsNeg flag
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