;=============================================================================;
;                                                                             ;
; Plik           : arch1-7c.asm                                               ;
; Format         : COM                                                        ;
; Cwiczenie      : Kompilacja, konsolidacja i debugowanie program�w           ;
;                  asemblerowych                                              ;
; Autorzy        : Emilia Masiak, Martyna Plutowska, 7.1, piatek, 12:15		  ;
; Data zaliczenia: 28.03.2025                                                 ;
; Uwagi          : Program obliczajacy wzor: (b*b-4*a)/d                      ;
;                                                                             ;
;=============================================================================;

                .MODEL  TINY ; 1 segment na wszystko (kod i dane) - 64KB

Kod             SEGMENT

; PSP to 256 bajtowa struktura kt�ra jest na samym szczycie pami�ci zarezerwowanej dla tego program
; zawiera np. argumenty linii polece� 
                ORG    100h ; 256 in hex, informujemy program, �e PSP jest dodawane
                ASSUME  CS:Kod, DS:Kod, SS:Kod ; ustawia rejestry segmentowe na segment Kod
; Informuje asembler, �e: Code, Data, Stack Segment wskazuj� na segment Kod.

Start: ; Start musi by� na pocz�tku segmentu, dlatego jako pierwsze musimy przeskoczy� do pocz�tku instrukcji (by nie odczytywa� danych jako instrukcji)
                jmp    Poczatek ; skok bezwarunkowy do etykiety

a               DB      20
b               DB      10
d               DB      3
Wynik           DB      ?

Poczatek:
				mov     al, 4
				mul     a ; al * a - wynik w ax
				mov 	bl, al ; Przechowujemy wynik z AL do BL (bo AL zaraz zostanie nadpisany).
                mov     al, b
                mul     b
                sub     al, bl
                div     d ; al / d - wynik do AL reszta w AH

                mov     Wynik, al

Koniec:         mov     ax, 4C00h ; ah - 4C (us�uga zako�czenia programu), al - kod powrotu  
                int     21h ; g��wne przerwanie kt�re udost�pnia wiele funkcji systemowych,
							; np. operacje na plikach, zarz�dzanie pami�ci�, obs�uga wej�cia/wyj�cia czy zako�czenie programu
							; warto�� rejestru AH okre�la konkretn� funkcj�.
							; przekazanie sterowania dla systemu operacyjnego

Kod             ENDS

                END    Start

