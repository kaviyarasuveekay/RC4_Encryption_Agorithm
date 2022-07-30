DATA SEGMENT
    rc4key DB 256 DUP(0)
    rc4x   DB 0
    rc4y   DB 0
    DATA_PROMPT  DB  'Enter Data: $'
    PROMPT  DB  'Enter key: $'
    keyString    db  255        ;MAX NUMBER OF CHARACTERS ALLOWED (255).
           db  ?         ;NUMBER OF CHARACTERS ENTERED BY USER.
           db  255 dup(0) ;CHARACTERS ENTERED BY USER.
    keylen DB 0

    plain_data  db  255
                db  ?
                db  255 dup(0)
    data_len DB 0
    result_prompt  DB  'CODE: $'
    new_line db 13, 10, "$"
DATA ENDS

CODE SEGMENT
     ASSUME DS:DATA,CS:CODE
START:
    mov ax, @data
    mov ds, ax
    mov ax, 0000h

;Accept Input
    LEA DX, DATA_PROMPT
    MOV AH, 09H
    INT 21H

    MOV AH, 0AH
    LEA DX, [plain_data]
    INT 21H                 

    ;CHANGE CHR(13) BY '$'.
    LEA si, [plain_data + 1]  ;NUMBER OF CHARACTERS ENTERED.
    mov cl, [si] ;MOVE LENGTH TO CL.
    mov data_len, cl
    mov ch, 0      ;CLEAR CH TO USE CX.
    inc cx ;TO REACH CHR(13).
    add si, cx ;NOW SI POINTS TO CHR(13).
    mov al, '$'
    mov [si], al ;REPLACE CHR(13) BY '$'. 
    
    ; new line
    LEA DX, new_line
    MOV AH, 09H
    INT 21H
    
    LEA DX, PROMPT
    MOV AH, 09H
    INT 21H

    MOV AH, 0AH
    LEA DX, [keyString]
    INT 21H                   

    ;CHANGE CHR(13) BY '$'.
    LEA si, [keyString + 1]
    mov cl, [si]
    mov keylen, cl
    mov ch, 0
    inc cx
    add si, cx
    mov al, '$'
    mov [si], al 

    ; new line
    LEA DX, new_line
    MOV AH, 09H
    INT 21H
  
    LEA DX, [keyString + 2]
    MOV AH, 09H
    INT 21H
    
    xor bx, bx                                              ; x = 0
    xor ax, ax                                              ; y = 0
    xor dx, dx 
    mov cx, 255
    ; for( x = 0; x < 256; x++ )
    ;       rc4key[ x ] = x;
initLoop:
    mov rc4key[bx], bl                                     ; rc4key[ x ] = x
    inc bl                                                 ; x++
    LOOP initLoop

    LEA si, [keyString + 2];
    xor ax, ax                                              ; y = 0
    xor bx, bx                                              ; x = 0
    xor cx, cx
    mov dh, keylen

keyLoop:
    mov cl, rc4key[bx]                                      ; sx = rc4key[x]
    add al, [si]                                            ; y += key[keypos]
    add al, cl                                              ; y += sx
    and ax, 256  
    mov di, ax
    mov ch, rc4key[di]
    mov rc4key[bx], ch                                      ; rc4key[x] = temp
    mov rc4key[di], cl                                      ; rc4key[y] = sx
    
    inc si                                                  ; ++keypos
    dec dh                                                  ; keylenTmp--
    jnz NoReset                                             ; if( keylenTmp )
    LEA si, [keyString + 2];                                ; keypos = 0
    mov dh, keylen
NoReset:
    inc bx                                                  ; Increment
    cmp bx, 255                                             ; Compare bx to the limit
    jle keyLoop                                             ; Loop while less or equal
  
    LEA si, [plain_data + 2];
    xor ax, ax                                              ; y = 0
    xor bx, bx                                              ; x = 0
    xor dx, dx
    mov dl, data_len
PRGA:
    inc bl                                                  ; x++
    and bx, 256                                             ; x mod 256   
    mov cl, rc4key[bx]                                      ; sx = rc4key[x]
    add al, cl                                              ; y += sx
    and ax, 256                                             ; y mod 256
    mov di, ax
    mov ch, rc4key[di]                                      ; sy = rc4key[y]
    mov rc4key[di], cl                                      ; rc4key[y] = sx
    mov rc4key[bx], ch                                      ; rc4key[x] = sy
    add cl, ch
    xor ch, ch
    mov di, cx                                              ; temp = (sx + sy) & 0xFF
    mov cl, rc4key[di]
    xor [si], cl                                            ; *data ^= rc4key[temp]
    inc si                                                  ; data++
    dec dx                                                  ; len--
    jnz PRGA

    LEA DX, new_line
    MOV AH, 09H
    INT 21H

    LEA DX, result_prompt
    MOV AH, 09H
    INT 21H
    
    LEA DX, [plain_data] + 2
    MOV AH, 09H
    INT 21H

    mov AH, 4CH
    mov AL, 00H
    INT 21H
CODE ENDS
END START