         ;�����嵥9-1
         ;�ļ�����c09_mbr.asm
         ;�ļ�˵����Ӳ���������������루���س��� 
         ;�������ڣ�2011-5-5 18:17���޸���2021-10-3 15:35
         
         app_lba_start equ 100           ;�����������û�������ʼ�߼������ţ�
                                         ;��������������ռ�û���ַ
                                    
SECTION mbr align=16 vstart=0x7c00                                     

         ;���ö�ջ�κ�ջָ�� 
         mov ax,0      
         mov ss,ax
         mov sp,ax
      
         mov ax,[cs:phy_base]            ;�������ڼ����û�������߼��ε�ַ 
         mov dx,[cs:phy_base+0x02]
         mov bx,16        
         div bx            
         mov ds,ax                       ;��DS��ESָ��ö��Խ��в���
         mov es,ax                        
    
         ;���¶�ȡ�������ʼ���� 
         xor di,di
         mov si,app_lba_start            ;������Ӳ���ϵ���ʼ�߼������� 
         xor bx,bx                       ;���ص�DS:0x0000�� 
         call read_hard_disk_0
      
         ;�����ж����������ж��
         mov dx,[2]                      ;������dxд����ds�����˶�ʮ�����Ŵ� 
         mov ax,[0]
         mov bx,512                      ;512�ֽ�ÿ����
         div bx
         cmp dx,0
         jnz @1                          ;δ��������˽����ʵ����������1 
         dec ax                          ;�Ѿ�����һ������������������1 
   @1:
         cmp ax,0                        ;����ʵ�ʳ���С�ڵ���512���ֽڵ���� 
         jz direct
         
         ;��ȡʣ�������
         push ds                         ;����Ҫ�õ����ı�DS�Ĵ��� 

         mov cx,ax                       ;ѭ��������ʣ����������
   @2:
         mov ax,ds
         add ax,0x20                     ;�õ���һ����512�ֽ�Ϊ�߽�Ķε�ַ
         mov ds,ax  
                              
         xor bx,bx                       ;ÿ�ζ�ʱ��ƫ�Ƶ�ַʼ��Ϊ0x0000 
         inc si                          ;��һ���߼����� 
         call read_hard_disk_0
         loop @2                         ;ѭ������ֱ�������������ܳ��� 

         pop ds                          ;�ָ����ݶλ�ַ���û�����ͷ���� 
      
         ;������ڵ����λ�ַ 
   direct:
         mov dx,[0x08] ;0x08-0x0a 
         mov ax,[0x06] ;0x06-0x08
         call calc_segment_base
         mov [0x06],ax                   ;�������������ڵ����λ�ַ 
      
         ;��ʼ�������ض�λ��
         mov cx,[0x0a]                   ;��Ҫ�ض�λ����Ŀ����
         mov bx,0x0c                     ;�ض�λ���׵�ַ
          
 realloc:
         mov dx,[bx+0x02]                ;32λ��ַ�ĸ�16λ 
         mov ax,[bx]
         call calc_segment_base
         mov [bx],ax                     ;����εĻ�ַ
         add bx,4                        ;��һ���ض�λ�ÿ��ռ4���ֽڣ� 
         loop realloc 
      
         jmp far [0x04]    ;7c70              ;ת�Ƶ��û�����  
 
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;��Ӳ�̶�ȡһ���߼�����
                                         ;���룺DI:SI=��ʼ�߼�������
                                         ;      DS:BX=Ŀ�껺������ַ
         push ax
         push bx
         push cx
         push dx
      
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;��ȡ��������

         inc dx                          ;0x1f3
         mov ax,si
         out dx,al                       ;LBA��ַ7~0

         inc dx                          ;0x1f4
         mov al,ah
         out dx,al                       ;LBA��ַ15~8

         inc dx                          ;0x1f5
         mov ax,di
         out dx,al                       ;LBA��ַ23~16

         inc dx                          ;0x1f6
         mov al,0xe0                     ;LBA28ģʽ������
         or al,ah                        ;LBA��ַ27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;������
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;��æ����Ӳ����׼�������ݴ��� 

         mov cx,256                      ;�ܹ�Ҫ��ȡ������
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [bx],ax        ; 这里ds已经被设置为指向0x10000地址的基地址，所以这里可以将内核程序读入到指定的位置 
         add bx,2
         loop .readw

         pop dx
         pop cx
         pop bx
         pop ax
      
         ret

;-------------------------------------------------------------------------------
calc_segment_base:                       ;����16λ�ε�ַ
                                         ;���룺DX:AX=32λ������ַ
                                         ;���أ�AX=16λ�λ���ַ 
         push dx                          
         ;20位右移4位 拿低16位 
         add ax,[cs:phy_base] ;此时ax拿到的是内核编译中的地址，也就是内核程序中的相对起始地址，在这里还需要加上实际加载的物理起始地址
         adc dx,[cs:phy_base+0x02]
         shr ax,4
         ror dx,4 ; 循环右移四位，这样拿到了最开始的四位 
         and dx,0xf000 ;only save high 4 bits 
         or ax,dx ; dx-high 4 bits + ax-low 12 bits 
         
         pop dx
         
         ret

;-------------------------------------------------------------------------------
         phy_base dd 0x10000             ;�û����򱻼��ص�������ʼ��ַ
         
 times 510-($-$$) db 0
                  db 0x55,0xaa
