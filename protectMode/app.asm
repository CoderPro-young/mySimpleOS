         ;�����嵥15-3���ļ�����c15_app.asm
         ;�ļ�˵�����û�����
         ;�޸���2022-02-28

;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ; program length #0x00
         
         head_len         dd header_end           ; header length #0x04

         prgentry         dd start                ;�������#0x08
         code_seg         dd section.code.start   ;�����λ��#0x0c
         code_len         dd code_end             ;����γ���#0x10

         data_seg         dd section.data.start   ;���ݶ�λ��#0x14
         data_len         dd data_end             ;���ݶγ���#0x18

        ;  stack_seg        dd section.stack.start  ;ջ��λ��#0x1c
        ;  stack_len        dd stack_end            ;ջ�γ���#0x20
             
;-------------------------------------------------------------------------------
         ;���ŵ�ַ������
         salt_items       dd (header_end-salt)/256 ;#0x24

         salt:                                     ;#0x28
         PrintString      db  '@PrintString'
                     times 256-($-PrintString) db 0

         TerminateProgram db  '@TerminateProgram'
                     times 256-($-TerminateProgram) db 0

         ReadDiskData     db  '@ReadDiskData'
                     times 256-($-ReadDiskData) db 0

header_end:

;===============================================================================
SECTION data vstart=0

         buffer times 1024 db  0         ;������

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:

;===============================================================================
SECTION stack vstart=0

        times 2048        db 0                    ;����2KB��ջ�ռ�

stack_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0

start:
         mov eax,ds
         mov fs,eax

        ;  mov ss,[fs:stack_seg]
        ;  mov esp,stack_end

         mov ds,[fs:data_seg]

         mov ebx,message_1
         call far [fs:PrintString]

         mov eax,100                         ;�߼�������100
         mov ebx,buffer                      ;������ƫ�Ƶ�ַ
         call far [fs:ReadDiskData]          ;�μ����

         mov ebx,message_2
         call far [fs:PrintString]

         mov ebx,buffer
         call far [fs:PrintString]           ;too.

         jmp far [fs:TerminateProgram]       ;������Ȩ���ص�ϵͳ

code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end:
