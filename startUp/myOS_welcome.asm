weclome_os_data_start equ 100 
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
        shl bx , 1
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

doShowOneStr:; bx->begin address ds: base reg  di: location for display in 0xb800 
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
    test al,al 
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

showUsrName:
    push bx 
    push dx
    call read_usr_message
    mov dx, 0 
    mov bx, buffer_name
    call doShowOneStr

    pop dx 
    pop bx 
    ret 
chooseOption:
    s:
        call showUsrName
        call showScreen
        call clearBuf
        mov ah,0
        int 16H 
        cmp al, '1'
        call do1 
        cmp al, '2'
        call do2 
        cmp al, '3'
        call do3 
        cmp al, '4'
        call do4 

        jmp s 
clearBuf: ; while loop to clean buffer 
    mov ah,1
    int 16h 
    jz clearBufRet
    mov ah,0 
    int 16h 
    jmp  clearBuf

clearBufRet:
    ret 

write_to_disk:
    ; di:si 目标扇区 高16位放di 低16位放si 
    ; ds 数据段基址 
    ; bx 数据总数 
        push ax
        push bx
        push cx
        push dx
    
        mov dx,0x1f2
        mov al,1
        out dx,al                       ;设置需要读写的扇区数量，通过0x1f2端口

        inc dx                          ;0x1f3
        mov ax,si
        out dx,al                       ;LBA地址7~0

        inc dx                          ;0x1f4
        mov al,ah
        out dx,al                       ;LBA地址15~8

        inc dx                          ;0x1f5
        mov ax,di
        out dx,al                       ;LBA 23~16

        inc dx                          ;0x1f6
        mov al,0xe0                     ;LBA28 
        or al,ah                        ;端口高四位为0x1110 低四位为扇区号的最高四位 
        out dx,al

        inc dx                          ;0x1f7
        mov al,0x30                     ;向端口发送写命令 
        out dx,al

.waits:
        in al,dx
        and al,0x88
        cmp al,0x08
        jnz .waits                      ;��æ����Ӳ����׼�������ݴ��� 

        mov cx,bx                      ;需要读写的字节数 
        mov dx,0x1f0                    ;从0x10读写数据 
        xor bx,bx 
.writew:
        mov ax,[bx] 
        out dx,ax
                
        add bx,2
        loop .writew

        pop dx
        pop cx
        pop bx
        pop ax
    
        ret

read_usr_name_from_disk:
    ; di:si 目标扇区 高16位放di 低16位放si 
    ; ds 数据段基址 
    ; bx 数据缓冲区 
        push ax
        push bx
        push cx
        push dx
    
        mov dx,0x1f2
        mov al,1
        out dx,al                       ;设置需要读写的扇区数量，通过0x1f2端口

        inc dx                          ;0x1f3
        mov ax,si
        out dx,al                       ;LBA地址7~0

        inc dx                          ;0x1f4
        mov al,ah
        out dx,al                       ;LBA地址15~8

        inc dx                          ;0x1f5
        mov ax,di
        out dx,al                       ;LBA 23~16

        inc dx                          ;0x1f6
        mov al,0xe0                     ;LBA28 
        or al,ah                        ;端口高四位为0x1110 低四位为扇区号的最高四位 
        out dx,al

        inc dx                          ;0x1f7
        mov al,0x20                     ;向端口发送read命令 
        out dx,al

.readwaits:
        in al,dx
        and al,0x88
        cmp al,0x08
        jnz .readwaits                      ;查看端口状态 

        mov dx,0x1f0                    ;从0x1f0读写数据 
        
.readw:
        in ax,dx 
        mov [bx],ax 
        add bx,2 
        cmp ax,0
        jnz .readw

        pop dx
        pop cx
        pop bx
        pop ax
    
        ret

read_usr_message:
    push bx 
    mov bx, buffer_name 
    call read_usr_name_from_disk
    pop bx 
    ret 

do1:
    call clearScreen
    mov ah,0 ;ah = 0 pop keyBoard ah = 1 isEmpty
    int 16H ; get dword byte form keyBoard ,ah = scanCode al = ascii 

    cmp ah ,0x01 
    jz do1End ; esc return choose 
do1End:    
    ret 

do2:
    push dx 
    call clearScreen
    mov ah,0 ;ah = 0 pop keyBoard ah = 1 isEmpty
    int 16H ; get dword byte form keyBoard ,ah = scanCode al = ascii 
    xor bx,bx 

    cmp ah ,0x01 
    jz do2End ; esc return choose 

    cmp ah, 0x1c ; if enter, end 
    jz do2End


    mov buffer_name[bx] , al 
    add bx,1 

    

do2End:
    test bx,bx 
    xor di,di 
    mov si, weclome_os_data_start 
    jnz write_to_disk 
    pop bx 
    ret 

do3:
    ret 

do4:
    ret 
start:
    ; 初始化段寄存器
    mov ax,[stack_segment]
    mov ss,ax 
    mov sp,256 ;0x00-0xff 共256
    mov ax,[data_1_segment]
    mov ds,ax 
    call read_usr_message 

    call clearScreen
    ; call showwelcome
    call chooseOption
    ; call showScreen 
    jmp $ 




code_1_end: 

SECTION code_2 align=16 vstart=0
    resb 256

;===============================================================================
SECTION data_1  align=16 vstart=0 
    buffer_name resb 64 ; 分配64字节
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

