;=============================================================================;
;                                                                             ;
; Plik           : arch1-7e.asm                                               ;
; Format         : EXE                                                        ;
; Cwiczenie      : Kompilacja, konsolidacja i debugowanie programów           ;
;                  asemblerowych                                              ;
; Autorzy        : Emilia Masiak, Martyna Plutowska, 7.1, piatek, 12:15		  ;
; Data zaliczenia: 28.03.2025                                                 ;
; Uwagi          : Program dokonujacy konkatenacji dwoch tekstow o znanej     ;
;                  dlugosci                                                   ;
;                                                                             ;
;=============================================================================;

                .MODEL  SMALL ; po 1 segment danych, kodu, stosu

Dane            SEGMENT

Napis1          DB      "To jest pierwszy napis"
DL_NAPIS1       EQU     $ - Napis1 ; obliczenia offsetu miêdzy aktualnym adresem a etykiet¹/zmienn¹
								   ; aktualny adres - adres zmiennej = d³ugoœæ napisu
Napis2          DB      "To jest drugi napis$"
DL_NAPIS2       EQU     $ - Napis2
Napis3          DB      DL_NAPIS1 + DL_NAPIS2 DUP (?)

Dane            ENDS

Kod             SEGMENT

                ASSUME   CS:Kod, DS:Dane, SS:Stosik

Start: ; etykieta, która nam wskazuje gdzie program ma siê zacz¹æ
                mov     ax, SEG Dane
                mov     ds, ax

                mov     si, OFFSET Napis1
                mov     di, OFFSET Napis3
                mov     cx, DL_NAPIS1

Petla1:
                mov     al, [si] ; odczytaj wartoœæ z si i wrzuæ do al
                mov     [di], al ; Procesory x86 nie pozwalaj¹ na bezpoœrednie kopiowanie pamiêci do pamiêci.
                inc     si ; przesuniêcie si na kolejny bajt
                inc     di
                loop    Petla1 ; Zmniejsz CX i jeœli nie jest 0, wróæ do Petla1

                mov     si, OFFSET Napis2
                mov     cx, DL_NAPIS2

Petla2:
                mov     al, [si]
                mov     [di], al
                inc     si
                inc     di
                loop    Petla2
				
                mov     ah, 09h ; funkcja DOS do wyœwietlania tekstu
                mov     dx, OFFSET Napis3 ; Za³adowanie adresu napisu Napis3 do rejestru DX
                int     21h

                mov     ax, 4C00h 
                int     21h

Kod            ENDS

Stosik          SEGMENT STACK

                DB      100h DUP (?) ; adresowanie 256 elementowej tablicy (nazwa anonimowa - nie musimy podawaæ nazwy)
									 ; DB - bajt, 100h DUP - zarezerwuj bajt 256 razy, (?) - nie inizjalizuj tej pamiêci
Stosik          ENDS

                END Start

