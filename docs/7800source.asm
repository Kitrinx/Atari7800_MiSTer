; NOTE: this is from a pre-release version dated 1984-04-23 at:
;   http://archives.atarimuseum.com/archives/pdf/videogames/7800/7800_os_source_code.pdf
;
; This does NOT match up with the "offical" version of the ROM!
;
; Places where code was unreadable (and not otherwise positively identifiable)
; are marked with "~~~", and chopped off ends of lines are marked with "...".
; If someone has access to a more readable copy, it would be nice to find out
; what the missing parts are.
;
; Depending on your assembler, at the very minimum, you will have to substitute
; "H(" -> ">(" and "L(" -> "<(", and probably "FATAL$" -> "FATAL" too, to get
; this to assemble.
;
STACKPTR  EQU     $FF ; could not find this in the source listing scan
;=====================================================================

*  MARIAOS        MARIA DATA LOCATION DEFINITIONS

*  NOTE THE FOLLOWING WIERD THINGS ABOUT THE RAM:
*           $00-$3F <=> $100-$13F
*           $80-$FF <=> $180-$1FF
*           $40-$FF <=> $2040-$20FF
*         $140-$1FF <=> $2140-$21FF

*  TIA REGISTERS
INPTCTRL  EQU     $01                    ;INPUT CONTROL
INPT4     EQU     $0C                    ;BITS 7        PLAYER 0 BUTTO...
INPT5     EQU     $0D                    ;BITS 7        PLAYER 1 BUTTO...
AUDC0     EQU     $15                    ;BITS     3210 AUDIO CONTROL ...
AUDC1     EQU     $16                    ;BITS     3210 AUDIO CONTROL ...
AUDF0     EQU     $17                    ;BITS    43210 AUDIO FREQUENC...
AUDF1     EQU     $18                    ;BITS    43210 AUDIO FREQUENC...
AUDV0     EQU     $19                    ;BITS     3210 AUDIO VOLUME 0...
AUDV1     EQU     $1A                    ;BITS     3210 AUDIO VOLUME 1...

*  MARIA REGISTERS
BACKGRND  EQU     $20                    ;BACKGROUND COLOR
P0C1      EQU     $21                    ;PALETTE 0, COLOR 1
P0C2      EQU     $22                    ;PALETTE 0, COLOR 2
P0C3      EQU     $23                    ;PALETTE 0, COLOR 3
WSYNC     EQU     $24                    ;FAST MARIA WSYNC STROBE
P1C1      EQU     $25                    ;PALETTE 1, COLOR 1
P1C2      EQU     $26                    ;PALETTE 1, COLOR 2
P1C3      EQU     $27                    ;PALETTE 1, COLOR 3
MSTAT     EQU     $28                    ;BIT 6 IN VBLANK, BIT ? IN D...
P2C1      EQU     $29                    ;PALETTE 2, COLOR 1
P2C2      EQU     $2A                    ;PALETTE 2, COLOR 2
P2C3      EQU     $2B                    ;PALETTE 2, COLOR 3
DPPH      EQU     $2C                    ;DISPLAY LIST POINTER HIGH
P3C1      EQU     $2D                    ;PALETTE 3, COLOR 1
P3C2      EQU     $2E                    ;PALETTE 3, COLOR 2
P3C3      EQU     $2F                    ;PALETTE 3, COLOR 3
DPPL      EQU     $30                    ;DISPLAY LIST POINTER LOW
P4C1      EQU     $31                    ;PALETTE 4, COLOR 1
P4C2      EQU     $32                    ;PALETTE 4, COLOR 2
P4C3      EQU     $33                    ;PALETTE 4, COLOR 3
CHARBASE  EQU     $34                    ;CHARACTER MODE HIGH POINTER
P5C1      EQU     $35                    ;PALETTE 5, COLOR 1
P5C2      EQU     $36                    ;PALETTE 5, COLOR 2
P5C3      EQU     $37                    ;PALETTE 5, COLOR 3
OFFSET    EQU     $38                    ;NOT USED ******
P6C1      EQU     $39                    ;PALETTE 6, COLOR 1
P6C2      EQU     $3A                    ;PALETTE 6, COLOR 2
P6C3      EQU     $3B                    ;PALETTE 6, COLOR 3
CTRL      EQU     $3C                    ;BIT 7 CHARACTER WIDTH, BIT 6...
P7C1      EQU     $3D                    ;PALETTE 7, COLOR 1
P7C2      EQU     $3E                    ;PALETTE 7, COLOR 2
P7C3      EQU     $3F                    ;PALETTE 7, COLOR 3

*  FREE RAM - $40-$FF

*  ALIASED RAM - $100-$13F

*  STACK - $140-$1FF

*  6532 TIMERS AND PORTS

SWCHA     EQU     $280                   ;JOYSTICKS
*         BIT 7   PLAYER 0 EAST IF CLEAR
*         BIT 6            WEST
*         BIT 5            SOUTH
*         BIT 4            NORTH
*         BIT 3   PLAYER 1 EAST IF CLEAR
*         BIT 2            WEST
*         BIT 1            SOUTH
*         BIT 0            NORTH

SWCHB     EQU     $282                   ;CONSOLE SWITCHES
*         BIT 7   PLAYER 1 DIFFICULTY A IF SET, B IF CLEAR
*         BIT 6   PLAYER 2 DIFFICULTY A IF SET, B IF CLEAR
*         BIT 3   BLACK AND WHITE VS COLOR - COLOR WHEN SET
*         BIT 1   GAME SELECT - CLEAR WHEN PRESSED
*         BIT 0   GAME RESET - CLEAR WHEN PRESSED

CTLSWA    EQU     $281
CTLSWB    EQU     $283
INTIM     EQU     $284                   ;INTERVAL TIMER IN
TIM8T     EQU     $295                   ;TIMER 8T WRITE OUT
TIM64T    EQU     $296                   ;TIMER 64T WRITE OUT
TIM64TI   EQU     $29E                   ;INTERRUPT TIMER 64T

*  ENDEF.S        ENCRYPTION SYMBOL DEFINITIONS
*  ADDRESS DEFINITIONS

*  PAGE 0 - $080-$0FF ($40-$7F TAKEN BY A REGISTER)

TEST0     EQU     $00                    ;TEST DATA FOR CPU TEST
TEST1     EQU     $01
TESTW0    EQU     $02                    ;2 BYTES
TESTW1    EQU     $04                    ;2 BYTES

TEMP0     EQU     $00                    ;SCRATCH DATA FOR PROGRAM USE...
TEMP1     EQU     $01                    ;MORE SCRATCH DATA
TEMP2     EQU     $02                    ;MORE SCRATCH DATA
TEMP3     EQU     $03                    ;MORE SCRATCH DATA
TEMP4     EQU     $04                    ;MORE SCRATCH DATA
TEMP5     EQU     $05                    ;MORE SCRATCH DATA

STARTA    EQU     $E0                    ;WHERE ACCUMULATOR STARTS
OFFSETA   EQU     $E1                    ;OFFSET INTO ACCUMULATOR
OFFSETR   EQU     $E2                    ;OFFSET INTO A REGISTER
SIZEA     EQU     $E3                    ;SIZE OF ACCUMULATOR
SIZER0    EQU     $E4                    ;SIZE OF REGISTER 0
SIZER1    EQU     $E5                    ;SIZE OF REGISTER 1
SIZER3    EQU     $E6                    ;SIZE OF REGISTER 3
SIZER5    EQU     $E7                    ;SIZE OF REGISTER 5

CARTBOTM  EQU     $EE                    ;BOTTOM OF CARTRIDGE ADDRESS
FUJICOLR  EQU     $EF                    ;STARTING COLOR FOR FUJI-A

KNLSTATE  EQU     $F0                    ;HOW MANY MORE ITERATIONS T...
KNLCOUNT  EQU     $F1                    ;TIMER FOR CHANGING FUJI COL...
KNLTIME   EQU     $F2                    ;TIME THAT COUNT IS GOOD FOR...
KNLOFSET  EQU     $F3                    ;HOW STAGGERED THE FUJI COLO...

DLIADDR   EQU     $F4                    ;SAME ADDRESS AS IN PACK-IN ...

*  HIGH RAM - $1800-$27FF

ACC       EQU     $1800                  ;256 BYTE ACCUMULATOR
REG0      EQU     $1900                  ;128 BYTE REGISTER
REG2      EQU     $1A00                  ;128 BYTE REGISTER
REG4      EQU     $1B00                  ;128 BYTE REGISTER
REG6      EQU     $1C00                  ;128 BYTE REGISTER
REG8      EQU     $1D00                  ;128 BYTE REGISTER
REG10     EQU     $1E00                  ;128 BYTE REGISTER
REG12     EQU     $1F00                  ;128 BYTE REGISTER

RAMGRAPH  EQU     $1984                  ;GRAHPICS IN RAM, $19XX-$1EXX
RAMDLL    EQU     $1F84                  ;DLL

REG1      EQU     $2000                  ;128 BYTE REGISTER

*         ***** HOLE FROM $2040 TO $20FF - SHADOWED IN PAGE 0 *****

REG14     EQU     $2100                  ;128 BYTE REGISTER (OVERLA~...

*         ***** HOLE FROM $2140 TO $21FF SHADOWED IN PAGE 1 *****

*  DISPLAY LIST RAM

RAMDLIST  EQU     $2200                  ;~~~ FOR DLISTS FOR WORDS AN...

*  MEMORY LOCATIONS FOR CO~~~~~~~~~~~~~~~~~~~~~~~~~~~

ROMCODE   EQU     $F400                  ;~~~~~~~~~~~~~~CODE LIVES
ROMCODE2  EQU     $F880                  ;~~~~~~~~~ DROPPED CODE
RAMCODE   EQU     $2300                  ;~~~~~~~~~~~~~~FOR CODE
CODEDIF   EQU     $D100                  ;DIFFERENCE BETWEEN OLD AND ...

*  ENCRYPTION CONST~~~~~~~~~~~~~~~~~~~

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        ;~~~~~~~~~~~ IS ON~~~~~~~~~

REGION    EQU     $FE                    ;MASK FOR COUNTRY

RANDBYTE  EQU     $04                    ;RANDOM BYTE IN CHECKSUM

*NTGAME   EQU     $D804                  ;INTERNAL GAME ROM START LOCA...
*NTDLI    EQU     $D800                  ;INTERNAL GAME DLI HANDLER
INTDLI    EQU     $F000                  ;OUR DLI


*  SCAFFOLD.S
*  THIS DOES THE DISPATCHING WHENEVER THE PACK-IN ISN'T AROUND

          ORG     INTDLI

          PHA
          JMP     (DLIADDR)


*  CART.S         ROUTINES DEALING WITH CHECKING THE CARTRIDGE OUT

          ORG     ROMCODE

NOCART    JMP     LOCK2600-CODEDIF       ;NO INTERNAL CART
*OCART    LDA     #$13                   ;TURN SECURITY ROM BACK ON - ...
*         STA     INPTCTRL
*         JSR     GRAPHON2
*
*         LDX     #$80
*OCTLOOP  LDA     KNLSTATE               ;WAIT A WHILE WITH THE DISPLA...
*         BNE     NOCTLOOP
*         LDA     #$00
*         STA     KNLSTATE
*         DEX
*         BNE     NOCTLOOP
*
*         JMP     INTGAME                ;JUMP TO INTERNAL GAME


BADCART   JMP     LOCK2600-CODEDIF       ;CART DOES NOT CHECK, DO 2600...


CARTTEST  LDA     #$16                   ;TURN EXTERNAL CART ON
          STA     INPTCTRL

          LDY     #$FF
          LDX     #$7F                   ;SEE IF A CART PLUGGED IN
CTSTLOOP  LDA     $FE00,X
          CMP     $FD80,Y
          BNE     NOCART
          DEY
          DEX
          BPL     CTSTLOOP               ;X LEFT = FF, Y LEFT = 7F

          LDA     $FFFC                  ;SEE IF START AT FFFF
          AND     $FFFD
          CMP     #$FF
          BEQ     NOCART                 ;ALL LINES DRAWN HIGH, NO CA...
          LDA     $FFFC                  ;SEE IF START AT 0000
          ORA     $FFFD
          BEQ     NOCART                 ;ALL LINES DRAWN LOW, NO CAR...

          LDA     $FFF8                  ;CHECK FOR REGION VERIFICATI...
          ORA     #REGION
          CMP     #$FF
          BNE     BADCART
          LDA     $FFF9                  ;SEE IF MARIA SIGNATURE EXIS...
          AND     #$0B                   ;$07 OR $03 VALID
          CMP     #$03
          BNE     BADCART
          LDA     $FFF9                  ;GET BOTTOM OF CART ADDRESS
          AND     #$F0
          STA     CARTBOTM
          STA     CSCMOD0+2-CODEDIF      ;SET UP FOR START OF CHECKSU...
          CMP     #$40                   ;MAKE SURE IT IS NOT TOO LOW
          BCC     BADCART
;         SEC
          SBC     #$01                   ;MAKE SURE WE GET FENCEPOST ...
          CMP     $FFFD                  ;MAKE SURE START VECTOR WITH...
          BCS     BADCART

          JSR     DECRYPT-CODEDIF        ;GET THE DECRYPTED CHECKSUM

          LDA     #$00
          STA     KNLSTATE               ;GET OUR STATE READY WITH DL...

          JSR     CSCHKDLI-CODEDIF       ;CHECK FOR COMING DLI

          LDA     #$16                   ;GENERATE THE CHECKSUM FOR C...
          STA     INPTCTRL               ;FIRST, TURN CART BACK ON
          LDX     #$00
          TXA
CS0LOOP   STA     ACC,X                  ;ZERO OUT THE CHECKSUM ACC
          DEX
          BNE     CS0LOOP

          PHA                            ;PUT 0 ON STACK TO INIT CSCH...
          LDY     #$7F                   ;Y STARTS = 7F
CSALOOP   LDA     $FF00,Y                ;GET HI PAGE INTO ACC
          STA     ACC,Y                  ;$FF00-$FF7F AND $FFF9-$FFFF
          DEY
          CPY     #$F8
          BNE     CSALOOP

          LDA     #L(S-CODEDIF)          ;SET UP FOR THE RETURN
          STA     CSCMOD1+1-CODEDIF
          LDA     #H(S-CODEDIF)
          STA     CSCMOD1+2-CODEDIF

CSCSLOOP  JSR     CSCHKDLI-CODEDIF       ;CHECK FOR COMING DLI
          PLA                            ;SAVE LOWER STATE
          JSR     CSCHECK-CODEDIF        ;MARCH UP THE CODE
          PHA                            ;PUT BACK LOWER STATE
          INC     CSCMOD0+2-CODEDIF
          LDA     CSCMOD0+2-CODEDIF
          CMP     #$FF
          BNE     CSCSLOOP

          JSR     CSCHKDLI-CODEDIF       ;CHECK FOR COMING DLI
          JSR     CSROTATE-CODEDIF       ;ROTATE THE BITS AROUND A BIT
          JSR     CSROTATE-CODEDIF       ;ROTATE THE BITS AROUND A BIT

          LDA     #L(T-CODEDIF)          ;SET UP FOR THE RETURN MARCH
          STA     CSCMOD1+1-CODEDIF
          LDA     #H(T-CODEDIF)
          STA     CSCMOD1+2-CODEDIF
          DEC     CSCMOD0+2-CODEDIF

CSCTLOOP  JSR     CSCHKDLI-CODEDIF       ;CHECK FOR COMING DLI
          PLA                            ;SAVE LOWER STATE
          JSR     CSCHECK-CODEDIF        ;MARCH UP THE CODE
          PHA                            ;PUT BACK LOWER STATE
          DEC     CSCMOD0+2-CODEDIF
          LDA     CSCMOD0+2-CODEDIF
          CMP     CARTBOTM
          BCS     CSCTLOOP

          LDA     #$60                   ;DONE WITH DECRYPT, TURN OF G...
          STA     CTRL

          LDX     #NLEN                  ;'FOLD' THE CHECKSUM TOGETHER
CSCFLOOP  LDA     ACC,X                  ;AND MOVE IT TO REG2
          EOR     ACC+$50,X
          EOR     ACC+$FF-NLEN,X
          STA     REG2,X
          DEX
          BPL     CSCFLOOP

          LDA     REG2                   ;MAKE SURE IT IS LESS THAN N
          AND     #NMASK
          STA     REG2

          LDA     #$00                   ;GET RID OF RANDOM BYTE
          LDX     #RANDBYTE
          STA     REG2,X
          STA     REG1,X

          LDX     #NLEN                  ;SEE IF THEY CHECK!!
CSCCLOOP  LDA     REG1,X                 ;THE DECRYPTED SIGNATURE
          CMP     REG2,X                 ;THE COMPUTED CHECKSUM
          BNE     NOCHECK
          DEX
          BPL     CSCCLOOP

          JMP     SETMARIA-CODEDIF       ;EVERYTHING CHECKS!!!!!

NOCHECK   JMP     LOCK2600-CODEDIF       ;DECRYPT FAILED, PUT HIM IN 2...

CSCHECK   LDX     #$00                   ;ROUTINE TO CHECKSUM ONE PAGE
CSCLOOP   ADC     ACC,X
CSCMOD0   ADC     $FF00,X
          TAY
CSCMOD1   LDA     N-CODEDIF,Y
          STA     ACC,X
          INX
          BNE     CSCLOOP
          RTS

CSROTATE  LDX     #$00                   ;ROUTINE TO ROTATE CHECKSUM A...
CSRLOOP   ROL     ACC,X
          INX
          BNE     CSRLOOP
          RTS

CSCHKDLI  PHP                            ;SAVE PROCESSOR STATUS
          DEC     KNLSTATE               ;SEE IF DLI ABOUT TO HAPPEN
          BPL     CSCDOUT                ;COUNT DOWN OUR TIMER

          LDA     #$02                   ;KERNEL NOT HAPPENED, BUT ABO...
          STA     INPTCTRL               ;DISABLE CART, TURN ON SECURI...
CSCDLOOP  LDA     KNLSTATE               ;AND THEN WAIT FOR THE KERNEL...
          BMI     CSCDLOOP
          LDA     #$16                   ;DISABLE SECURITY ROM, TURN O...
          STA     INPTCTRL

CSCDOUT   PLP                            ;RESTORE PROCESSOR STATUS
          RTS

*  THESE TABLES ARE USED FOR NON-LINEAR ~~~~~~~~~~~
S         DB      $C7,$65,$AB,$CA,$EE,$F7,$83,$09
T         DB      $E1,$D0,$92,$67,$62,$B6,$72,$55
          DB      $8E,$91,$DC,$C5,$81,$BE,$78,$20
          DB      $59,$B7,$E6,$3D,$06,$45,$AF,$C8
          DB      $08,$31,$38,$D1,$FB,$73,$84,$A9
          DB      $17,$FC,$34,$87,$A3,$94,$FA,$90
          DB      $B8,$ED,$CE,$3B,$5B,$0A,$43,$D9
          DB      $F3,$53,$82,$B3,$0D,$6D,$5A,$60
          DB      $9D,$51,$A7,$B9,$11,$10,$BC,$E4
          DB      $7F,$80,$41,$E7,$E3,$F6,$56,$26
          DB      $35,$EC,$D6,$DF,$0C,$7F,$F4,$9E
          DB      $AC,$52,$46,$EF,$CF,$BF,$A2,$3F
          DB      $A4,$13,$15,$97,$4A,$1C,$B0,$42
          DB      $8C,$B1,$05,$58,$80,$18,$77,$2B
          DB      $02,$3E,$A8,$49,$1A,$6A,$CB,$6E
          DB      $0B,$8A,$EB,$F1,$4F,$14,$79,$8B
          DB      $D8,$9F,$9B,$57,$19,$F8,$2A,$2D
          DB      $76,$0E,$E8,$2E,$4B,$F9,$07,$03
          DB      $DE,$93,$16,$7E,$D4,$E5,$B2,$F0
          DB      $7D,$7A,$DA,$D2,$A1,$CC,$1D,$E0
          DB      $5E,$23,$A0,$95,$22,$1E,$36,$85
          DB      $FE,$1F,$39,$AA,$89,$96,$AD,$0F
          DB      $2F,$C0,$47,$27,$5D,$24,$EA,$C3
          DB      $A5,$F5,$21,$5F,$1B,$40,$8F,$AE
          DB      $74,$25,$DD,$C1,$7C,$CD,$A6,$70
          DB      $D7,$33,$7B,$2C,$75,$BB,$86,$99
          DB      $BD,$54,$9A,$6C,$63,$32,$48,$4C
          DB      $8D,$BA,$5C,$61,$C4,$4E,$29,$37
          DB      $12,$C6,$98,$9C,$D5,$69,$6B,$E2
          DB      $04,$4D,$E9,$C2,$88,$3A,$DB,$64
          DB      $01,$44,$6F,$B5,$F2,$30,$28,$FD
          DB      $50,$71,$3C,$B4,$66,$68,$C9,$D3
          DB      $CA,$83,$C7,$AB,$F7,$65,$09,$EE

*  METHOD.S       THIS IS A PACKAGE OF ROUTINES THAT DO THE ACTUAL DE...

*  THIS ROUTINE DECRYPTS A SIGNATURE.  THE KEY IS PLACED INTO REG1.
*  MODULUS IS N.  EVERYTHING IS ASSUMED TO BE SIZE NLEN.
*         INPUT:  SIG IN $FF80, N, NLEN
*         OUTPUT: DECRYPTED SIG IN REG1 (LENGTH NLEN)
*  REG1 = SIG * SIG MOD N  (DECRYPTION FUNCTION)
DECRYPT   LDX     #NLEN
          STX     SIZER0
          STX     SIZER1

DCLOOP    LDA     $FF80,X
          STA     REG0+1,X
          STA     REG1,X
          DEX
          BPL     DCLOOP

          LDA     #$02                   ;TURN SECURITY ROM BACK ON
          STA     INPTCTRL
          JSR     GRAPHON                ;TURN GRAPHICS ON

          JSR     MULTIPLY-CODEDIF       ;START WITH THE MULTIPLY
          DEC     KNLTIME                ;SPEED UP FUJI ROLLING

          LDX     #NLEN                  ;SIZE OF REGISTER
          STX     SIZER0                 ;SET UP SIZE FOR DIVIDE
MDMRLOOP  LDA     N,X                    ;MOVE MODULO TO REG0
          STA     REG0+1,X               ;STORE IT
          DEX
          BPL     MDMRLOOP               ;KEEP GOING TILL REGISTER 0 ...

          LDA     OFFSETA
          STA     SIZEA
          JSR     DIVIDE-CODEDIF         ;AND DO THE DIVIDE
          DEC     KNLTIME                ;SPEED UP FUJI ROLLING

          LDA     STARTA                 ;SET UP FOR MOVE
          STA     DCMOD0+1-CODEDIF
          LDX     #NLEN                  ;PUT ACC INTO REG1
DCMLOOP
DCMOD0    LDA     ACC,X
          STA     REG1,X
          DEX
          BPL     DCMLOOP

          RTS                            ;ALL DONE, GET CHECKSUM TO C...


*  MULTIPLY TWO NUMBERS - THE TWO NUMBERS TO BE MULTIPLIED ARE PLACED...
*  REG0 AND REG1.  THE RESULT IS LEFT IN ACC.  ACC WILL HAVE A LEADIN...
*  (TO MAKE IT EASIER TO USE WITH A MODULO FOLLOWING IT).  REG0 SHOUL...
*  AT REG0+1 (SO THE FIRST LOCATION CAN BE SMASHED) THOUGH SIZER0 SHO...
*  REMAIN UNCHANGED.
*         INPUT:  REG0, REG1, SIZER0, SIZER1
*         OUTPUT: ACC, STARTA, OFFSETA
MULTIPLY  JSR     SETREGS-CODEDIF        ;INITIALIZE REGISTERS
          LDY     SIZER1                 ;PREPARE ACCUMULATOR
          INY
          STY     OFFSETA                ;OFFSET INTO REG0 AND ACC
          TYA
          CLC
          ADC     OFFSETR                ;SET SIZE TO CLEAR
          PHA                            ;PUSH SIZE OF ACCUMULATOR ON...
          TAX
          LDA     #$00
          STA     ADDMOD+1-CODEDIF       ;WE ONLY USE EVEN REGISTERS
MULCALP   STA     ACC,X                  ;CLEAR ACC
          DEX
          BNE     MULCALP
          STA     ACC                    ;CLEAR LEADING BYTE
          INY                            ;Y STILL ~~~~~~SETA, INC FOR...
          STY     ADACMOD0+1-CODEDIF     ;MODIFY ~~~ACCUMULATOR INDEX...
          STY     ADACMOD1+1-CODEDIF
          STY     ADACMOD2+1-CODEDIF
          STY     ADACMOD3+1-CODEDIF

MULLOOP0  LDX     #$00                   ;RESET BIT OFFSET
          DEC     ADACMOD0+1-CODEDIF     ;MODIFY ~~~~ACCUMULATOR INDEX...
          DEC     ADACMOD1+1-CODEDIF
          DEC     ADACMOD2+1-CODEDIF
          DEC     ADACMOD3+1-CODEDIF
          DEC     OFFSETA                ;GO TO NEXT REG1 BYTE
          BMI     MULOUT
MULLOOP   LDY     OFFSETA                ;GET OFFSET INTO REG0
          LDA     REG1,Y                 ;SEE WHAT OUR 'CURRENT BIT' ...
          AND     MULTMASK-CODEDIF,X
          BEQ     MULNEXT
          LDA     HSEROFF-CODEDIF,X      ;IT IS A 1, ADD IN APPROPRIA...
          STA     ADDMOD+2-CODEDIF
          JSR     MULTADD-CODEDIF

MULNEXT   INX                            ;GO TO NEXT BIT IN BYTE
          CPX     #$08
          BMI     MULLOOP
          JMP     MULLOOP0-CODEDIF

MULOUT    PLA                            ;GET SIZE OF ACCUMULATOR BAC...
          STA     OFFSETA
          LDA     #$01                   ;STARTING BYTE OF ACCUMULATO...
          STA     STARTA
          RTS

MULTMASK  DB      $01,$02,$04,$08,$10,$20,$40,$80


*  DIVIDE TWO NUMBERS - THE ACCUMULATOR IS DIVIDED BY REG0.  THE REMA...
*  PLACED IN REG1.  THE ACCUMULATOR MUST START OUT WITH A NULL HI BYT...
*  (THE INITIAL STARTA OF 1, THE FIRST BYTE OF ACC IS ZEROED HERE).
*  AS IN MULTIPLY, REG0 SHOULD START AT REG0+1.
*         INPUT:  ACC, REG0, SIZER0, SIZEA
*         OUTPUT: ACC, STARTA, OFFSETA
*         USES:   REG2-REG14 EVEN
DIVIDE    JSR     SETREGS-CODEDIF        ;SET SHIFTED REGISTERS

          LDA     SIZEA

          SEC
          SBC     SIZER0
          STA     STARTA                 ;THIS IS THE START OF WHAT IS...
          STA     OFFSETA                ;THIS IS NUMBER OF TIMES LOOP...

          LDX     #$00
          STX     ACC                    ;MAKE SURE LEADING BYTE IS 2
          STX     SUBMOD+1-CODEDIF       ;WE ONLY USE EVEN REGISTERS
          STX     CMPMOD+1-CODEDIF
          DEX                            ;THESE WILL BE INCREMENTED ON...
          STX     CMACMOD+1-CODEDIF
          STX     SBACMOD0+1-CODEDIF
          STX     SBACMOD1+1-CODEDIF
          STX     SBACMOD2+1-CODEDIF
          STX     SBACMOD3+1-CODEDIF

DIVLOOP0  LDX     #$07                   ;RESET BIT OFFSET
          INC     CMACMOD+1-CODEDIF
          INC     SBACMOD0+1-CODEDIF
          INC     SBACMOD1+1-CODEDIF
          INC     SBACMOD2+1-CODEDIF
          INC     SBACMOD3+1-CODEDIF
          DEC     OFFSETA
          BMI     DIVOUT
DIVLOOP   LDA     HSEROFF-CODEDIF,X       ;DO MODIFICATION FOR COMPARE
          STA     SUBMOD+2-CODEDIF
          STA     CMPMOD+2-CODEDIF
          JSR     DIVCOMP-CODEDIF         ;SEE IF REGISTER IS LARGER
          BCC     DIVNEXT                 ;  IF SO, DO NOTHING
          JSR     DIVSUB-CODEDIF          ;AND DO THE SUBTRACT

DIVNEXT   DEX                             ;GO TO NEXT BIT IN BYTE
          BPL     DIVLOOP
          JMP     DIVLOOP0-CODEDIF

DIVOUT    LDA     SIZEA                   ;SET LAST RETURN VALUE
          STA     OFFSETA                 ;THIS IS THE END OF WHAT IS L...
          RTS


*  THIS ROUTINE SETS UP REGISTERS FOR MULTIPLY AND DIVIDE.  THE REGIST...
*  IS SHIFTED LEFT 7 TIMES, WITH THE INTERMEDIATE FORMS LEFT IN REG2-R...
*  (IN ORDER OF HOW MUCH THEY HAVE BEEN SHIFTED).  IT IS ASSUMED THAT ...
*  A LEADING ZERO.  THE LEADING BYTE IS ZEROED SO WHOEVER LOADS REG0 ~...
*  HAVE TO ZERO IT.  NOTE THAT SIZER0 SHOULD NOT INCLUDE THE LEADING Z...
*         INPUT:  REG0, SIZER0
*         OUTPUT: REG0-REG14 EVEN, OFFSETR (INDEX INTO ABOVE)
SETREGS   LDX     SIZER0
          INX
          STX     OFFSETR


          LDY     #$00
          STY     REG0                     ;CLEAR THE EXTRA BYTE.
SERLOOP   LDA     HSEROFF-CODEDIF,Y
          STA     SERSMOD1+2-CODEDIF
          INY                              ;GO TO NEXT REG
          LDA     HSEROFF-CODEDIF,Y
          STA     SERSMOD2+2-CODEDIF

          LDX     OFFSETR                  ;DO A LEFT SHIFT OF THE REGIS...
          CLC
SERSLOOP
SERSMOD1  LDA     REG0,X                   ;GET DATA
          ROL     A                        ;ROTATE IT
SERSMOD2  STA     REG0,X                   ;STORE IT
          DEX
          BPL     SERSLOOP

          CPY     #$07
          BMI     SERLOOP

SEROUT    RTS

*  OFFSET TABLES AND MASK BYTES USED BY SETTINGS
HSEROFF   DB      H(REG0),H(REG2),H(REG4),H(REG6)
          DB      H(REG8),H(REG10),H(REG12),H(REG14)


*  ADD TWO NUMBERS - CALLER MODIFIES ADDMOD+1,ADDMOD+2 TO THE ADDRESS ...
*  REGISTER TO BE ADDED IN.  CALLER MODIFIES ADACMOD0..3+1 FOR OFFSET ...
*  ACCUMULATOR.
*         INPUT:  ACC, REGN, OFFSETR, X
*         OUTPUT: ACC
*  ACC = ACC + REGN
MULTADD   LDY     OFFSETR                ;START AT THE END OF THE REGI...
          CLC
ADDLOOP
ADACMOD0  LDA     ACC,Y                  ;ADD THE REGISTER TO THE ACCU...
ADDMOD    ADC     REG0,Y
ADACMOD1  STA     ACC,Y
          DEY
          BPL     ADDLOOP                ;KEEP GOING TILL REGISTER EXHA...

ADDLOOP2  BCC     ADDOUT                 ;IF CARRY CLEAR, ALL DONE
ADACMOD2  LDA     ACC-$100,Y             ;PROPAGATE CARRY (Y IS WRAPPED...
          ADC     #$00
ADACMOD3  STA     ACC-$100,Y
          DEY
          JMP     ADDLOOP2-CODEDIF
ADDOUT    RTS


*  SUBTRACT TWO NUMBERS - CALLER MODIFIES SUBMOD+1,SUBMOD+2 TO THE AD...
*  THE REGISTER TO BE SUBTRACTED.  CALLER MODIFIES SBACMOD0..3+1 TO T...
*  INTO THE ACCUMULATOR.
*         INPUT:  ACC, REGN, OFFSETR, X
*         OUTPUT: ACC
*  ACC = ACC - REGN
DIVSUB    LDY     OFFSETR               ;START AT THE END OF THE REG...
          SEC
SUBLOOP
SBACMOD0  LDA     ACC,Y                 ;ADD THE REGISTER TO THE ACC...
SUBMOD    SBC     REG0,Y
SBACMOD1  STA     ACC,Y
          DEY
          BPL     SUBLOOP               ;KEEP GOING TILL REGISTER EX...

SUBLOOP2  BCS     SUBOUT                ;IF CARRY CLEAR, ALL DONE
SBACMOD2  LDA     ACC-$100,Y            ;PROPAGATE CARRY (Y IS WRAPP...
          SBC     #$00
SBACMOD3  STA     ACC-$100,Y
          DEY
          JMP     SUBLOOP2-CODEDIF
SUBOUT    RTS


*  COMPARE TWO NUMBERS - CALLER MODIFIES CMPMOD+1,CMPMOD+2 TO THE ADD...
*  THE REGISTER TO BE SUBTRACTED.  CMACMOD+1 IS MODIFIED FOR THE OFFS...
*  THE ACCUMULATOR.
*         INPUT:  ACC, REGN, OFFSETR
*         OUTPUT: CARRY SET IF REGISTER LESS THAN ACCUMULATOR
DIVCOMP   LDY     #$00                   ;START AT THE TOP OF THE REG...

CMPLOOP
CMACMOD   LDA     ACC,Y                  ;ADD THE REGISTER TO THE ACC...
CMPMOD    CMP     REG0,Y
          BEQ     CMPNEXT
CMPOUT    RTS

CMPNEXT   CPY     OFFSETR                ;WE HAVE TO LOOK AT ANOTHER,...
          BEQ     CMPOUT                 ;  HAVE MADE IT TO THE END O...
          INY                            ;NO, DO ANOTHER BYTE
          JMP     CMPLOOP-CODEDIF


*  VECTOR.S       WE HAVE DETERMINED VALIDITY, VECTOR TO CART IN 2600...
*                 3600 MODE


SETMARIA  LDX     #$16                   ;~~~~~~~~~IN 3600 MODE, CART...
          STX     INPTCTRL
          TXS
          SED
          JMP     ($FFFC)                ;VECTOR INTO THE CART IN 360...


LOCK2600  LDA     #$02                   ;TURN SECURITY ROM ON
          STA     INPTCTRL               ;LOCK CART IN 2600 MODE, CART...
          LDX     #$7F                   ;MOVE CODE TO RAM
L2LOOP    LDA     SYNC,X                 ;MOVE INTO 6532 RAM
          STA     $480,X
          DEX
          BPL     L2LOOP
          JMP     $480                   ;AND EXECUTE OUT OF RAM

SYNC      LDA     #0
          TAX
ZEROLP    STA     1,X
          INX
          CPX     #$2C
          BNE     ZEROLP
          LDA     #4
          STA     2
          LDA     #4
          NOP
          BMI     E
          LDX     #4
DEX       DEX
          BPL     DEX
          TXS
          STA     $110
          JSR     DUMMY+1-SYNC+$480
          JSR     DUMMY+1-SYNC+$480
          STA     $11
          STA     2
          STA     $1B
          STA     $1C
          STA     $F
          STA     2
          BIT     3
          BMI     OUT
E         LDA     #2
          STA     9
          STA     $F112
          BNE     DONE
OUT       BIT     2
          BMI     DONE
          LDA     #2
          STA     6
          STA     $F118
DUMMY     STA     $F460
DONE      LDA     #$FD
          STA     8
          JMP     ($FFFC)


ENDROM    NOP                            ;END OF FIRST PART OF ROM

*  TEST.S         RAM AND CPU TESTS - IF EITHER ARE BAD, DECRYPTION WI...
*                 THUS, THESE MUST BE TESTED FIRST

* ***** NOTE: *****  THE FOLLOWING INSTRUCTIONS ARE NOT TESTED BY THE...
*  AND THUS SHOULD NOT BE USED IN THE VALIDATION/DECRYPTION CODE:
*         BRK, RTI, PLP, PHP, CLV, SEV, BVC, BVS, CLD, SED, BIT, SEI,...


*  TEST FAILURE MODES
BADCPU    EQU     $00                    ;CPU ERROR
BAD6116A  EQU     $01                    ;ERROR IN RAM $2000-$27FF
BAD6116B  EQU     $02                    ;ERROR IN RAM $1800-$1FFF
BADRAM    EQU     $03                    ;CAN'T GET TO ANY OF THE RAM
BADMARIA  EQU     $04                    ;MARIA SHADOWING NOT WORKING
BADVALID  EQU     $05                    ;BAD VALIDATION OR DECRYPTION


          ORG     ROMCODE2

FATAL$    LDA     #$1D                   ;THERE HAS BEEN SOMETHING BA...
          STA     INPTCTRL               ;LOCK IN 2600 MODE, TEST CART...

MAIN      SEI                            ;INITIALIZE
          CLD

          LDA     #$02                   ;PUT BASE UNIT INTO MARIA ENA...
          STA     INPTCTRL

          LDA     #H(ENDDLI)             ;WESTBERG SUX
          STA     DLIADDR+1              ;WESTBERG SUX
          LDA     #L(ENDDLI)             ;WESTBERG SUX
          STA     DLIADDR                ;WESTBERG SUX

          LDA     #$7F
          STA     CTRL                   ;TURN OFF DMA
          LDA     #$00
          STA     BACKGRND               ;BACKGROUND COLOR TO BLACK


* ***** RAM TESTS *****

*  A SIMPLE RAM TEST TO CHECK PAGES $2000 AND $2100 IS DONE FIRST TO ...
*  ENOUGH RAM TO TEST OUT THE CPU (SHADOWED TO PAGES $0000 AND $0100).
*  THE CPU TEST, A FULL RAM TEST IS DONE

*  EARLY RAM TEST, JUST CHECK OUT OUR TWO PAGES USING MINIMAL INSTRUC...
RAMCHECK  LDX     #$05                   ;TEST OUT 4 PATTERNS OF RAM
RCAGAIN   LDA     RAMPAT,X
          LDY     #$00
RCLOOP    STA     $2000,Y                ;CHECK ZERO PAGE
          CMP     $2000,Y
          BNE     CHKRAMB
          STA     $2100,Y                ;CHECK PAGE 1
          CMP     $2100,Y
          BNE     CHKRAMB
          DEY
          BNE     RCLOOP
          DEX
          BPL     RCAGAIN

* SEE IF MARIA SHADOWING WORKS
          LDA     #$43                   ;A SIMPLE ~~~~ TO SEE IF SHAD...
          STA     $2080
          CMP     $0080
          BNE     MARIAERR
          STA     $2180
          CMP     $0180
          BNE     MARIAERR

          JMP     CPUTEST                ;IF SHADOW~~~~~~~ RAM WORKS, ...


* RAM FAILURE ROUTINES

MARIAERR  LDY     #BADMARIA              ;MARIA SHADOWING BAD
          JMP     FATAL$

CHKRAMB   STA     $1800                  ;RAMA HAS FAILED IN SIMPLE TE...
          CMP     $1800                  ;  TO SEE IF ANY RAM WORKS
          BNE     RAMERR

RAMAERR   LDY     #BAD6116A              ;BAD RAM CHIP - $2000-$27FF
          JMP     FATAL$

RAMBERR   LDY     #BAD6116B              ;BAD RAM CHIP - $1800-$1FFF
          JMP     FATAL$

RAMERR    LDY     #BADRAM                ;ALL RAM BAD - COULD BE ANOTH...
          JMP     FATAL$


*  A FULL RAM TEST, TO BE DONE AFTER THE CPU TEST SUCEEDS

RAMTEST   LDA     #$00                   ;SET UP STATE TO MARCH THROU...
          STA     $F0                    ;(F0) = $2000
          STA     $F2                    ;(F2) = $1800
          LDY     #$07                   ;NUMBER OF PAGES TO CHECK
          STY     $F4

RTPAGE    LDA     RAMAPAGE,Y             ;SET UP RAM A PAGE TO CHECK
          STA     $F1
          LDA     RAMBPAGE,Y             ;SET UP RAM B PAGE TO CHECK
          STA     $F3
          LDX     #$05                   ;NUMBER OF RAM PATTERNS TO C...

RTPAT     LDA     RAMPAT,X               ;GET RAM PATTERN
          LDY     #$00                   ;INITIALIZE INDEX

RTLOOP    STA     ($F0),Y                ;CHECK RAM A
          CMP     ($F0),Y
          BNE     RAMAERR
          STA     ($F2),Y                ;CHECK RAM B
          CMP     ($F2),Y
          BNE     RAMBERR
          DEY
          BNE     RTLOOP

          DEX
          BPL     RTPAT

          DEC     $F4                    ;ONE LESS PAGE
          LDY     $F4
          BPL     RTPAGE
          JMP     STARTVND               ;START THE VALIDATION AND DE...


RAMPAT    DB      $00,$FF,$55,$AA,$69,$0F            ;PATTERNS FOR RA...
RAMAPAGE  DB      $22,$23,$24,$25,$26,$27,$22,$23    ;HI BYTES OF RAM...
RAMBPAGE  DB      $18,$19,$1A,$1B,$1C,$1D,$1E,$1F    ;HI BYTES OF RAM...


* ***** CPU TESTS *****

IRQINT                                   ;IF WE GET AN IRQ, IT IS A C...
CPUERR    LDY     #BADCPU                ;CPU ERROR
          JMP     FATAL$

* CPU TEST, METHODICALLY CHECK ALL INSTRUCTIONS, ADDRESSING MODES, AN...
*  BITS THAT THE DECRYPTION WILL BE USING

CPUTEST   LDA     #$AA                   ;FIRST, TEST OUT LDA AND BRA
          BEQ     CPUERR                 ;CHECK BEQ FAIL
          BPL     CPUERR                 ;CHECK BPL FAIL
          BMI     CTA                    ;CHECK BMI SUCCEED
          JMP     CPUERR
CTA       BNE     CTB                    ;CHECK BNE SUCCEED
          JMP     CPUERR
CTB       STA     $AA                    ;STORE IT ~~~~~ $AA = AA
          CMP     $AA                    ;SEE IF IT ADDRESSES AND COM...
          BNE     CPUERR

          LDA     #$00                   ;TEST ALTERNATE POLARITY
          BNE     CPUERR                 ;CHECK BNE FAIL
          BMI     CPUERR                 ;CHECK BMI FAIL
          BPL     CTC                    ;CHECK BPL SUCCEED
          JMP     CPUERR
CTC       BEQ     CTD                    ;CHECK BEQ SUCCEED
          JMP     CPUERR
CTD       CMP     #$00
          BNE     CPUERR                 ;CHECK CMP FAIL
          BCC     CPUERR                 ;CHECK BCC FAIL
          BCS     CTE                    ;CHECK BCS SUCCEED
          JMP     CPUERR
CTE       CMP     #$01
          BCS     CPUERR                 ;CHECK BCS FAIL
          BCC     CTF                    ;CHECK BCC SUCCEED
          JMP     CPUERR


CTF       LDX     #$55                   ;TEST X AND Y LOADS, STORES
          CPX     #$56                   ;CHECK CPX
          BEQ     CPUERR
          STX     $1AA                   ;CHECK STX - $1AA = 55
          CPX     $1AA                   ;CHECK CPX
          BNE     CPUERR
          LDY     $AA                    ;CHECK LDY, - Y = AA
          CPY     #$AB
          BEQ     CPUERR
          STY     $155                   ;CHECK STY - $155 = AA
          CPY     $155                   ;CHECK CPY
          BNE     CPUERR

          DEX                            ;CHECK TRANSFER DATA PATHS A...
          TXS                            ;TO POINT TO $155, S MUST BE...
          INX
          PLA                            ;S HAS 55, A = $155 (= AA)
          CMP     #$AA                   ;TEST TXS AND PLA
          BNE     CPUERR0
          TXA                            ;A = 55
          PHA                            ;$155 = 55
          CPX     $155                   ;TEST TXA DNA PHA
          BNE     CPUERR0
          TYA                            ;A = AA
          CMP     #$AA                   ;TEST TYA
          BNE     CPUERR0
          TAX
          LDA     $100,X                 ;NORM,X - A = $1AA (= 55)
          TAY                            ;Y = 55
          CPY     #$55                   ;TEST NORM,X, TAX, TAY
          BNE     CPUERR0


                                         ;TEST ADDRESSING MODES (NORM...
          LDA     $00,X                  ;ZP,X - A = $AA (= AA)
          CMP     $AA                    ;ZP, TEST ZP AND ZP,X
          BNE     CPUERR0
          CMP     #$AA                   ;TEST ZP AND ZP,X
          BNE     CPUERR0
          EOR     #$FF                   ;A = 55
          STA     $00,Y                  ;ZP,Y - $55 = 55
          CMP     $55
          BNE     CPUERR0
          CMP     $100,Y                 ;NORM,Y ($155)
          BNE     CPUERR0
          CMP     $20AB,X                ;NORM,X W/WRAP ($155)
          BNE     CPUERR0

          LDA     #$20                   ;SET UP ADDR, TEST (IND,X), (...
          STA     $F1
          LDA     #$CC
          STA     $F0                    ;($F0) = $20CC (WHICH IS $CC)
          STA     ($F0-$AA,X)            ;(IND,X) - $CC = CC
          CMP     $CC
          BNE     CPUERR0
          STA     ($F0),Y                ;(IND),Y - $2121 = CC
          CMP     $2121
          BNE     CPUERR0
          LDA     #L(CTCONT)             ;TEST (IND), ONLY JMP USES
          STA     $F0
          LDA     #H(CTCONT)
          STA     $F1
          JMP     ($F0)                  ;(IND)
          JMP     CPUERR0


CPUERR0   JMP     CPUERR                 ;ANOTHER CPUERR


CTCONT    LDA     #$55                   ;TEST ADDER
          CLC
          ADC     #$55                   ;55 - 55 = AA
          NOP                            ;NOP, MAKE SURE IT DOESN'T A...
          BCS     CPUERR0
          BPL     CPUERR0
          BEQ     CPUERR0
          CMP     #$AA
          BNE     CPUERR0
;         SEC
          ADC     #$55                   ;AA + 55 + C = 0 + C
          NOP                            ;NOP, MAKE SURE IT DOESN'T AL...
          BCC     CPUERR0
          BMI     CPUERR0
          BNE     CPUERR0

;         SEC                            ;TEST SU~~~~~~~~~
          SBC     #$55                   ;0 - 55 ~~~~~~~~~
          BCS     CPUERR0
          BPL     CPUERR0
          BEQ     CPUERR0
          CMP     #$AB
          BNE     CPUERR0
          CLC
          SBC     #$AA                   ;AB - AA ~~~~~~~~
          BCC     CPUERR0
          BMI     CPUERR0
          BNE     CPUERR0


          LDA     #$FF                   ;TEST OUT INCREMENTS AND DEC...
          TAX                            ;X = FF
          INX                            ;TEST INX - X = 0
          BNE     CPUERR1
          DEX                            ;TEST DEX - X = FF
          BEQ     CPUERR1
          BPL     CPUERR1
          CPX     #$FF
          BNE     CPUERR1
          TAY                            ;Y = FF
          INY                            ;TEST INY - Y = 0
          BNE     CPUERR1
          DEY                            ;TEST DEY - Y = FF
          BEQ     CPUERR1
          INY                            ;Y = 0
          BNE     CPUERR1
          STA     $F0                    ;$F0 = FF
          INC     $F0                    ;TEST INC - $F0 = 0
          BNE     CPUERR1
          CPY     $F0
          BNE     CPUERR1
          DEC     $F0                    ;TEST DEC - $F0 = FF
          BEQ     CPUERR1
          CMP     $F0
          BNE     CPUERR1


          LDA     #$AA                   ;TEST SHIFTS AND ROTATES - 1...
          CLC                            ;C = 0
          ROL     A                      ;01010100, C=1
          ROL     A                      ;10101001, C=0
          ROL     A                      ;01010010, C=1
          CMP     #$52                   ;01010010
          BNE     CPUERR1

;         SEC                            ;C = 1
          ROR     A                      ;10101001, C=0
          ROR     A                      ;01010100, C=1
          ROR     A                      ;10101010, C=0
          CMP     #$AA                   ;10101010
          BEQ     CTSHIFT


CPUERR1   JMP     CPUERR                 ;ANOTHER CPUERR


CTSHIFT   ASL     A                      ;01010100, C=1
          BCC     CPUERR1
          ASL     A                      ;10101000, C=0
          BCS     CPUERR1
          ASL     A                      ;01010000, C=1
          CMP     #$50
          BNE     CPUERR1

          EOR     #$05                   ;01010101
          LSR     A                      ;00101010, C=1
          BCC     CPUERR1
          LSR     A                      ;00010101, C=0
          BCS     CPUERR1
          LSR     A                      ;00001010, C=1
          CMP     #$0A
          BNE     CPUERR1


          LDA     #$55                   ;TEST LOGICAL OPERATIONS
          ORA     #$1B                   ;TEST OR - A = 5F
          CMP     #$5F
          BNE     CPUERR1
          AND     #$55                   ;A = 55
          AND     #$1B                   ;TEST AND - A = 11
          CMP     #$11
          BNE     CPUERR1
          ORA     #$55                   ;A = 55
          EOR     #$1B                   ;TEST EOR
          CMP     #$4E
          BNE     CPUERR1


          JSR     CTJSR                  ;GRAND FINALE, TEST JSR, S =...
CTJSRRET  JMP     CPUERR1                ;NO GOOD IF WE DIDN'T JSR

CTJSR     TSX                            ;SEE WHERE STACK IS
          CPX     #$52
          BNE     CPUERR1
          PLA                            ;GET RETURN ADDRESS
          CMP     #L(CTJSRRET-1)
          BNE     CPUERR1
          PLA
          CMP     #H(CTJSRRET-1)
          BNE     CPUERR1
          LDA     #H(RAMTEST-1)          ;PUT START OF CODE AS RETURN
          PHA
          LDA     #L(RAMTEST-1)
          PHA
          RTS                            ;DO IT
          JMP     CPUERR1                ;AGAIN, NO GOOD IF WE DI...


*  KERNEL.S       DLI ROUTINES FOR THE SECURITY ROM

*  OUR DLI HANDLER
DLI       TXA                            ;STACK REGISTERS, A ALRE...
          PHA

          LDA     #$43
          STA     CTRL
          LDX     #$0F
          LDA     FUJICOLR
          STA     P0C2                   ;INITIALIZE COLOR
          BIT     KNLOFSET               ;FIGURE OUT STAGGERING
          BVC     DFJMP1
          BPL     DFJMP0
DFLOOP    STA     WSYNC                  ;CHANGE COLOR ONCE PER ...
DFJMP0    STA     WSYNC                  ;SECOND LINE
DFJMP1    STA     WSYNC                  ;THIRD LINE
          SEC
          SBC     #$10
          CMP     #$10
          BCS     DFNEXT
          SBC     #$0F
DFNEXT    STA     P0C2                   ;CHANGE COLORS
          DEX
          BPL     DFLOOP

DLIATARI  LDX     #$40                   ;SET UP CTRL FOR ATARI
          STX     CTRL

          AND     #$F0
          ORA     #$0E
          STA     P1C3

          LDA     FUJICOLR
          AND     #$F0
          ORA     #$06
          STA     P1C1
          AND     #$F0
          CLC                            ;ROTATE BAR COLOR
          ADC     #$40
          BCC     DLAJMP
          ADC     #$0F
DLAJMP    ORA     #$03
          STA     P1C2

          DEC     KNLCOUNT               ;SEE IF TIME FOR A COLOR...
          BPL     DLIDONE

          LDA     KNLOFSET               ;SEE IF TIME TO STAGGER, OR ...
          ADC     #$60
          BCC     DLIOFSET
          LDA     FUJICOLR               ;ROTATE FUJI COLOR
          CLC
          ADC     #$10
          BCC     DLJMP0
          ADC     #$0F
DLJMP0    STA     FUJICOLR
          LDA     KNLTIME                ;RESET TIMER
          STA     KNLCOUNT

          LDA     #$00
DLIOFSET  STA     KNLOFSET               ;UPDATE KERNAL STAGGERING CO...
DLIDONE   LDA     #$02                   ;NOTE THAT WE HAVE DONE KERN...
          STA     KNLSTATE
          PLA                            ;UNSTACK REGISTERS
          TAX
ENDDLI    PLA
          RTI

INFLOOP   JMP     INFLOOP

*  MAIN.S         MAIN ROUTINE FOR DECRYPTION CODE
*  CALLED FROM ROUTINES IN TESTS.S

STARTVND  LDX     #STACKPTR
          TXS                            ;SET STACK POINTER

          LDA     #0                     ;ZERO THE TIA REGISTERS OUT
          TAX
TIA0LOOP  STA     1,X
          INX
          CPX     #$2C
          BNE     TIA0LOOP
          LDA     #$02                   ;BACK INTO MARIA MODE
          STA     INPTCTRL

*  THIS ROUTINE DROPS OUR CODE INTO RAM
DROPRAM   LDX     #$00                   ;X = 0, DROP CODE AND GRAPHI...
          STX     BACKGRND               ;PUT BACKGROUND TO BLACK

DRLOOP    LDA     ROMCODE+$000,X         ;DROP CODE
          STA     RAMCODE+$000,X
          LDA     ROMCODE+$100,X
          STA     RAMCODE+$100,X
          LDA     ROMCODE+$200,X
          STA     RAMCODE+$200,X
          LDA     ROMCODE+$300,X
          STA     RAMCODE+$300,X
          LDA     ROMCODE+$400,X
          STA     RAMCODE+$400,X
          LDA     ROMDLIST,X             ;DROP DISPLAY LISTS
          STA     RAMDLIST,X
          CPX     #$00
          BMI     DRLJMP0
          LDA     ROMDLL,X               ;DROP DL~~~~~~
          STA     RAMDLL,X
          LDA     ROMGRPH6,X             ;DROP GRAPHICS INTO HALF PAGE
          STA     RAMGRAPH+$000,X
          LDA     ROMGRPH5,X
          STA     RAMGRAPH+$100,X
          LDA     ROMGRPH4,X
          STA     RAMGRAPH+$200,X
          LDA     ROMGRPH3,X
          STA     RAMGRAPH+$300,X
          LDA     ROMGRPH2,X
          STA     RAMGRAPH+$400,X
          LDA     ROMGRPH1,X
          STA     RAMGRAPH+$500,X
DRLJMP0   DEX
          BNE     DRLOOP

          JMP     CARTTEST-CODEDIF       ;START THE DECRYPTION


*  TURN THE GRAPHICS ON
GRAPHON   LDA     $FFF9                  ;SEE IF DISPLAY IS TO BE START...
          AND     #$04
          BEQ     STRTCRPT

GRAPHON2  LDA     #$03                   ;SET UP KERNEL
          STA     KNLCOUNT
          STA     KNLTIME

          LDA     #$49                   ;SET COLOR
          STA     FUJICOLR
          LDA     #$66
          STA     P1C1
          LDA     #$56
          STA     P1C2
          LDA     #$2E
          STA     P1C3

          LDA     #L(DLI)                ;SET DLI
          STA     DLIADDR
          LDA     #H(DLI)
          STA     DLIADDR+1

SCREENOF  BIT     MSTAT                  ;IS VBLANK ENDED YET?
          BMI     SCREENOF
SCREENON  BIT     MSTAT                  ;IS VBLNAK STARTED YET?
          BPL     SCREENON

          LDA     #L(RAMDLL)
          STA     DPPL                   ;SET DPPL AND DPPH TO DLLIST
          LDA     #H(RAMDLL)
          STA     DPPH
          LDA     #$43
          STA     CTRL                   ;TURN GRAPHICS ON

STRTCRPT  RTS


*  DISPLAY LISTS
ROMDLIST  DB      L(RAMGRAPH),$1F,H(RAMGRAPH),$BB,$00,$00        ;4 BY...
RDL5BYTE  DB      L(RAMGRAPH),$40,H(RAMGRAPH),$1F,$BB,$00,$00    ;5 BY...
RDLFUJI1  DB      L(RAMGRAPH+ROMFUJI1-ROMGRAPH),$1C,H(RAMGRAPH),$4A,$00,$00
RDLFUJI2  DB      L(RAMGRAPH+ROMFUJI2-ROMGRAPH),$1C,H(RAMGRAPH),$4A,$00,$00
RDLFUJI3  DB      L(RAMGRAPH+ROMFUJI3-ROMGRAPH),$1C,H(RAMGRAPH),$48,$00,$00
RDLFUJI4  DB      L(RAMGRAPH+ROMFUJI4-ROMGRAPH),$1B,H(RAMGRAPH),$46,$00,$00
RDLFUJI5  DB      L(RAMGRAPH+ROMFUJI5-ROMGRAPH),$19,H(RAMGRAPH),$42,$00,$00
RDLFUJI6  DB      L(RAMGRAPH+ROMFUJI6-ROMGRAPH),$17,H(RAMGRAPH),$3E,$00,$00
RDLFUJI7  DB      L(RAMGRAPH+ROMFUJI7-ROMGRAPH),$17,H(RAMGRAPH),$3E,$00,$00
RDLRACE   DB      L(RAMGRAPH+ROMSTRIP-ROMGRPH3),$2C,H(RAMGRAPH+$300),$00
          DB      L(RAMGRAPH+ROMSTRIP-ROMGRPH3),$2C,H(RAMGRAPH+$300),$50,$00,$00
RDLRACEL  DB      L(RAMGRAPH+ROMSTRIP-ROMGRPH3),$2C,H(RAMGRAPH+$400),$00
          DB      L(RAMGRAPH+ROMSTRIP-ROMGRPH3),$2C,H(RAMGRAPH+$400),$50,$00,$00
RDLINE01  DB      L(RAMGRAPH+ROMLINE1-ROMGRAPH),$2D,H(RAMGRAPH+$000),$28,$00,$00
RDLINE02  DB      L(RAMGRAPH+ROMLINE2-ROMGRAPH),$2D,H(RAMGRAPH+$000),$28,$00,$00
RDLINE03  DB      L(RAMGRAPH+ROMLINE3-ROMGRAPH),$2D,H(RAMGRAPH+$000),$28,$00,$00
RDLINE04  DB      L(RAMGRAPH+ROMLINE4-ROMGRAPH),$2D,H(RAMGRAPH+$000),$28,$00,$00
RDLINE05  DB      L(RAMGRAPH+ROMLINE1-ROMGRAPH),$2D,H(RAMGRAPH+$100),$28,$00,$00
RDLINE06  DB      L(RAMGRAPH+ROMLINE2-ROMGRAPH),$2D,H(RAMGRAPH+$100),$28,$00,$00
RDLINE07  DB      L(RAMGRAPH+ROMLINE3-ROMGRAPH),$2D,H(RAMGRAPH+$100),$28,$00,$00
RDLINE08  DB      L(RAMGRAPH+ROMLINE4-ROMGRAPH),$2D,H(RAMGRAPH+$100),$28,$00,$00
RDLINE09  DB      L(RAMGRAPH+ROMLINE1-ROMGRAPH),$2D,H(RAMGRAPH+$200),$28,$00,$00
RDLINE10  DB      L(RAMGRAPH+ROMLINE2-ROMGRAPH),$2D,H(RAMGRAPH+$200),$28,$00,$00
RDLINE11  DB      L(RAMGRAPH+ROMLINE3-ROMGRAPH),$2D,H(RAMGRAPH+$200),$28,$00,$00

*  DISPLAY LIST LIST
ROMDLL    DB      $0F,H(RAMDLIST),L(RAMDLIST+RDL5BYTE-ROMDLIST)  ;5 BY...
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $03,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $85,H(RAMDLIST),L(RAMDLIST+RDLFUJI1-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI2-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI3-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI4-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI5-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI6-ROMDLIST)
          DB      $05,H(RAMDLIST),L(RAMDLIST+RDLFUJI7-ROMDLIST)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)    ;CENTER SPACE
          DB      $01,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)   ;ATAR...
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE01-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE02-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE03-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE04-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE05-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE06-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE07-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE08-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE09-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE10-ROMDLIST)
          DB      $02,H(RAMDLIST),L(RAMDLIST+RDLRACE-ROMDLIST)
          DB      $00,H(RAMDLIST),L(RAMDLIST+RDLINE11-ROMDLIST)
          DB      $01,H(RAMDLIST),L(RAMDLIST+RDLRACEL-ROMDLIST)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)        ;TRAILING SPA...
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)
          DB      $0F,H(RAMDLIST),L(RAMDLIST+$00)


*  ROM GRAPHICS FOR THE FUJI-A AND WORDS
ROMGRAPH
ROMGRPH6  DB      $00                    ;NULL INFO
ROMFUJI1  DB      $7C,$7F,$8F,$80        ;LINE 6
ROMFUJI2  DB      $FC,$7F,$8F,$C0
ROMFUJI3  DB      $1F,$87,$F8,$7E
ROMFUJI4  DB      $0F,$E0,$7F,$81,$FC
ROMFUJI5  DB      $07,$FF,$80,$7F,$80,$7F,$F8
ROMFUJI6  DB      $1F,$FF,$F0,$00,$7F,$80,$03,$FF,$FE
ROMFUJI7  DB      $1F,$00,$00,$00,$7F,$80,$00,$00,$3E

ROMLINE1  DB      $00,$00,$0C,$00,$3F,$FF,$FF,$FF        ;LINE 1 OF A...
          DB      $F0,$00,$C0,$00,$00,$3F,$FF,$FF
          DB      $00,$03,$FC
ROMLINE2  DB      $00,$00,$3F,$00,$3F,$FF,$FF,$FF        ;LINE 2 OF A...
          DB      $F0,$03,$F0,$00,$00,$3F,$FF,$FF
          DB      $FC,$03,$FC
ROMLINE3  DB      $00,$00,$FF,$C0,$00,$03,$FF,$00        ;LINE 3 OF ...
          DB      $00,$0F,$FC,$00,$00,$3F,$F0,$03
          DB      $FF,$C3,$FC
ROMLINE4  DB      $00,$03,$FF,$F0,$00,$03,$FF,$00        ;LINE 4 OF AT...
          DB      $00,$3F,$FF,$00,$00,$3F,$F0,$00
          DB      $3F,$C3,$FC

ROMGRPH5  DB      $00                    ;NULL INFO
          DB      $7C,$7F,$8F,$80        ;LINE 5
          DB      $7C,$7F,$8F,$80
          DB      $1F,$87,$F8,$7E
          DB      $0F,$F0,$7F,$83,$FC
          DB      $01,$FF,$80,$7F,$80,$7F,$E0
          DB      $1F,$FF,$F8,$00,$7F,$80,$07,$FF,$FE
          DB      $1F,$F0,$00,$00,$7F,$80,$00,$03,$FE

          DB      $00,$0F,$F3,$FC,$00,$03,$FF,$00        ;LINE 5 OF ...
          DB      $00,$FF,$3F,$C0,$00,$3F,$F0,$00
          DB      $FF,$C3,$FC
          DB      $00,$3F,$C0,$FF,$00,$03,$FF,$00        ;LINE 6 OF ...
          DB      $03,$FC,$0F,$F0,$00,$3F,$F0,$3F
          DB      $FC,$03,$FC
          DB      $00,$FF,$00,$3F,$C0,$03,$FF,$00        ;LINE 7 OF ...
          DB      $0F,$F0,$03,$FC,$00,$3F,$F0,$FF
          DB      $C0,$03,$FC
          DB      $03,$FF,$FF,$FF,$F0,$03,$FF,$00        ;LINE 8 OF ...
          DB      $3F,$FF,$FF,$FF,$00,$3F,$F0,$3F
          DB      $F0,$03,$FC

ROMGRPH4  DB      $00                    ;NULL INFO
          DB      $7C,$7F,$8F,$80        ;LINE 4
          DB      $7C,$7F,$8F,$80
          DB      $1F,$87,$F8,$7E
          DB      $07,$F0,$7F,$83,$F8
          DB      $00,$FF,$C0,$7F,$80,$FF,$C0
          DB      $1F,$FF,$FC,$00,$7F,$80,$0F,$FF,$FE
          DB      $1F,$FC,$00,$00,$7F,$80,$00,$0F,$FE

          DB      $0F,$FF,$FF,$FF,$FC,$03,$FF,$00        ;LINE 9 OF ...
          DB      $FF,$FF,$FF,$FF,$C0,$3F,$F0,$0F
          DB      $FC,$03,$FC
          DB      $3F,$F0,$00,$03,$FF,$03,$FF,$03        ;LINE 10 OF...
          DB      $FF,$00,$00,$3F,$F0,$3F,$F0,$03
          DB      $FF,$03,$FC
          DB      $FF,$C0,$00,$00,$FF,$C3,$FF,$0F        ;LINE 11 OF A...
          DB      $FC,$00,$00,$0F,$FC,$3F,$F0,$00
          DB      $FF,$C3,$FC

ROMGRPH3  DB      $00                    ;NULL INFO
          DB      $7C,$7F,$8F,$80        ;LINE 3
          DB      $7C,$7F,$8F,$80
          DB      $0F,$87,$F8,$7C
          DB      $07,$F0,$7F,$83,$F8
          DB      $00,$7F,$C0,$7F,$80,$FF,$80
          DB      $1F,$FF,$FE,$00,$7F,$80,$1F,$FF,$FE
          DB      $1F,$FF,$00,$00,$7F,$80,$00,$3F,$FE

ROMSTRIP  DB      $55,$55,$55,$55,$55,$55,$55,$55        ;RACING STR...
          DB      $55,$55,$55,$55,$55,$55,$55,$55
          DB      $55,$55,$55,$55

ROMGRPH2  DB      $00                    ;NULL INFO
          DB      $7C,$7F,$8F,$80        ;LINE 2
          DB      $7C,$7F,$8F,$80
          DB      $0F,$C7,$F8,$FC
          DB      $03,$F0,$7F,$83,$F0
          DB      $00,$3F,$E0,$7F,$81,$FF,$00
          DB      $01,$FF,$FE,$00,$7F,$80,$1F,$FF,$E0
          DB      $1F,$FF,$C0,$00,$7F,$80,$00,$FF,$FE

          DB      $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA        ;RACING STR...
          DB      $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
          DB      $AA,$AA,$AA,$AA

ROMGRPH1  DB      $00                    ;NULL INFO
          DB      $7C,$7F,$8F,$80        ;LINE 1
          DB      $7C,$7F,$8F,$80
          DB      $0F,$C7,$F8,$FC
          DB      $03,$F8,$7F,$87,$F0
          DB      $00,$1F,$E0,$7F,$81,$FE,$00
          DB      $00,$1F,$FF,$00,$7F,$80,$3F,$FE,$00
          DB      $1F,$FF,$E0,$00,$7F,$80,$01,$FF,$FE

          DB      $55,$55,$55,$55,$55,$55,$55,$55        ;RACING STR...
          DB      $55,$55,$55,$55,$55,$55,$55,$55
          DB      $55,$55,$55,$55


*  NUMBERS.S      NUMBERS FOR THE ENCRYPTION ~~~~~~~~~


*  THIS IS A MASK APPLIED TO THE HI BYTE OF TH~~~~~~~~~~~ MAKE SURE...
*  LESS THAN N
NMASK     EQU     $07

*  N = P*Q, THE BASIC MODULO OF DECRYPTION
NLEN      EQU     $77
N         DB      $09,$CA,$C9,$C6,$B4,$12,$08,$1B
          DB      $60,$58,$81,$4B,$86,$01,$D8,$BF
          DB      $D9,$25,$A0,$7B,$DC,$32,$79,$84
          DB      $3B,$7C,$BC,$2F,$E2,$E2,$FA,$8D
          DB      $0A,$00,$3B,$C5,$EC,$AF,$2D,$8A
          DB      $CD,$06,$93,$6A,$A5,$14,$46,$77
          DB      $C4,$6A,$B2,$53,$36,$EF,$8C,$CE
          DB      $0C,$A2,$68,$71,$D3,$73,$E8,$F7
          DB      $6D,$06,$B5,$20,$EF,$23,$47,$0C
          DB      $51,$55,$C8,$FE,$F4,$58,$C4,$3F
          DB      $20,$A7,$67,$38,$B0,$76,$E2,$C4
          DB      $D8,$05,$63,$F8,$3C,$58,$3B,$2D
          DB      $22,$CC,$88,$B3,$71,$8F,$1D,$80
          DB      $0A,$87,$BD,$A1,$59,$23,$E9,$70
          DB      $E2,$D3,$EC,$46,$68,$80,$42,$39


*  END.S          END OF CODE

ENDROM2   NOP

          ORG     $FFEE
          DB      'GCC(C)1984'

          ORG     $FFF8
          DB      $F0                    ;CHECKSUM, MAKES EOR CHECK...
          DB      $F7                    ;CART STARTS AT $F000 - 7 ...
          DW      INTDLI                 ;INTERNAL GAME DLI HANDLER
          DW      MAIN
          DW      IRQINT

          END
