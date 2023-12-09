SECTION header vstart=0
    program_length  dd program_end  ; 0x00 length 
    code_entry      dw start        ; 0x04 
                    dd section.code_1.start ; 0x06 
    
    realloc_tbl_len dw (header_end-code_1_segment)/4
                                            ;表项数目[0x0a]
    
    ;重定位表            
    code_1_segment  dd section.code_1.start ;[0x0c]
    code_2_segment  dd section.code_2.start ;[0x10]
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c]
    
    header_end:        

SECTION code_1 align=16 vstart=0   

clearScreen:
    push cx 
    push bx
    push es 
    push di  

    mov bx, 0b800H 
    mov es, bx 
    mov cx, 2000
    mov di, 0  
    clearChar:
        mov byte  es:[di], ' '
        add di, 2
        loop clearChar

    pop di  
    pop es 
    pop bx 
    pop cx 
    ret


showScreen:; show all line in screen

    push ax 
    push ds 
    push cx 
    push bx 
    push dx 

    ; mov ax,[data_1_segment]
    ; mov ds,ax 
    mov cx,2 
    mov bx,0 

    
    mov dx,10 

    showOneLine: 

        mov ax,160 
        push dx 
        mul dx ; ax = ax * dx  next dx = 0 
        
        mov di,ax 
        add di,30*2 
        push bx 
        add bx,bx 
        mov bx,strTable[bx] ; get address of string 
        call doShowOneStr

        pop bx
        inc bx  
        pop dx 
        inc dx 
        
        loop showOneLine

    pop dx 
    pop bx 
    pop cx 
    pop ds 
    pop ax 
    ret 

doShowOneStr:; bx->begin address ds: base reg 
    push si 
    push ax 
    push es 
    push cx 

    mov si,0 
    mov ax,0b800H 
    mov es,ax 
    mov cx,80 ; 一行做多显示80个字符 
    ;mov di,160*10+30*2 

    
    mov al, ds:[bx+si] ; 实质实现了一个while循环，先做一步并判断是否满足条件，不满足直接return 
    cmp al,0
    je doShowOneStrRet
    cpyChar:   
        ; mov al,ds:[bx+si]
        ; cmp al,0 
        ; je doShowOneStrRet
        mov es:[di],al 
        inc si 
        add di,2 
        mov al,ds:[bx+si] 
        cmp al,0

        jne cpyChar ; 满足循环条件，jmp回去继续计算 

     
doShowOneStrRet:  
    ; pop di 
    pop cx 
    pop es 
    pop ax
    pop si 
    ret 

start:
    ; 初始化段寄存器
    mov ax,[stack_segment]
    mov ss,ax 
    mov sp,256 
    mov ax,[data_1_segment]
    mov ds,ax 

    call clearScreen
    ; call showwelcome
    call showScreen 
    jmp $ 


code_1_end: 

SECTION code_2 align=16 vstart=0
    resb 256

;===============================================================================
SECTION data_1  align=16 vstart=0 
    msg db "This is data_1",0 
strTable dw first, second  ; 这里存储了几个字符串的偏移地址 
first db "1) clock",0
second db "2) set name",0


data_1_end: 
SECTION data_2 align=16 vstart=0 
    resb 256

;===============================================================================
SECTION stack align=16 vstart=0
           
         resb 256

stack_end:  

;===============================================================================
SECTION trail align=16
program_end:

