org 0x7c00  ; org用来指定程序的起始地址，如果程序没有使用org伪指令，编译器默认0x0000作为程序起始地址
BaseOfStack equ 0x7c00 ; equ是让左边的标识符代表右边的表达式，类似于宏定义，BaseOfStack用于为栈指针寄存器SP提供栈基址
BaseOfLoader equ 0x1000
OffsetLoader equ 0x00

RootDirSectors equ 14
SectorNumOfRootDirStart equ 19
SectorNumOfFAT1Start equ 1
SectorBalance equ 17

    jmp short Label_Start
    nop
    ;=======FAT12 文件系统的一些定义========
    BS_OEMName db 'MZWMINEboot' ;生产厂商名字
    BPB_BytesPerSec dw 512 ;每个扇区的字节数
    BPB_SecPerClus db 1 ;每个簇的扇区数
    BPB_RsvdSecCnt dw 1 ;保留扇区数
    BPB_NumFats db 2 ;FAT表的份数
    BPB_RootEntCnt dw 224 ;根目录可容纳的目录项数
    BPB_TotSec16 dw 2880 ;总扇区数
    BPB_Media db 0xf0 ;介质描述符（软盘硬盘）
    BPB_FATSz16 dw 9 ;每个FAT表的扇区数
    BPB_SecPerTrk dw 18 ;每个磁道的扇区数
    BPB_NumHeads dw 2 ;磁头数
    BPB_hiddSec dd 0 ;隐藏扇区数
    BPB_TotSec32 dd 0 ;如果BPB_TotSec16的值为0，则由这个值记录扇区数
    BS_DrvNum db 0 ;int13h 的驱动器号
    BS_Reservedl db 0 ;未使用
    BS_BootSig db 29h ;扩展引导标记
    BS_VolID dd 0 ;卷序列号
    BS_VolLab db 'boot loader' ;卷标，相当于C盘名称
    BS_FileSysType db 'FAT12    ' ;文件系统类型
    ;=======FAT12 文件系统的一些定义  End========


;======= 真正的boot程序从这里开始
Label_Start:

    mov ax , cs
    mov ds , ax
    mov es , ax
    mov ss , ax
    mov sp , BaseOfStack

;========  clear screen  AH = 06h的功能是按指定范围滚动窗口
; 
    mov ax , 0600h
    mov bx , 0700h
    mov cx , 0
    mov dx , 0184fh
    int 10h

;======= set focus    AH = 02h的功能是设置光标位置
; 将屏幕的光标位置设置在屏幕的左上角（0，0），不论是行号还是列号均从0开始，坐标原点位于屏幕左上角
    mov ax , 0200h
    mov bx , 0000h
    mov dx , 0000h
    int 10h

;======= display on screen : Start Booting   AL = 13h功能是显示一行字符串
    mov ax , 1301h  ; AL = 01h显示后光标会移动至字符串尾端的位置
    mov bx , 000fh
    mov dx , 0000h
    mov cx , 10
    push ax
    mov ax , ds
    mov es , ax
    pop ax
    mov bp , StartBootMessage
    int 10h

;======= reset floppy  AH = 00h的功能是int13h的BIOS中断服务程序
    xor ah , ah
    xor dl , dl
    int 13h

    jmp $

    StartBootMessage : db "Start Boot"

;======= others
    times 510 - ( $ - $$ ) db 0
    dw 0xaa55  

;======= read one sector from floppy
Func_ReadOneSector:
    push bp
    mov bp , sp
    sub esp , 2
    mov byte [bp - 2] , cl
    push bx
    mov bl , [BPB_SecPerTrk]
    div bl
    inc ah
    mov cl , ah
    mov dh , al
    shr al . 1
    mov ch , al
    and dh , 1
    pop bx
    mov dl , [BS_DrvNum]
Label_Go_On_Reading:
    mov ah  , 2
    mov al , byte [bp - 2]
    int 13h
    jc Label_Go_On_Reading
    add esp , 2
    pop bp
    ret
 ;======= search loader.bin
    mov word [SectorNo] , SectorNumOfRootDirStart
Label_Search_In_Root_Dir_Begin:

    cmp word [RootDirSizeForLoop] , 0
    jz Label_No_LoaderBin
    dec word [RootDirSizeForLoop]
    mov ax , 00h
    mov es , ax
    mov bx , 8000h
    mov ax , [SectorNo]
    mov cl , 1
    call Func_ReadOneSector
    mov si , LoaderFileName
    mov di , 8000h
    cld
    mov dx , 10h

Label_Search_For_LoaderBin:

    cmp dx , 0
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    mov cx , 11

Label_Cmp_FileName:
    cmp cx , 0
    jz Label_FileName_Found
    dec cx
    lodsb
    cmp al , byte [es:di]
    jz Label_Go_On
    jmp Label_Different

Label_Go_On:
    inc di
    jmp Label_Cmp_FileName

Label_Different:
    and di , 0ffe0h
    add di , 20h
    mov si , LoaderFileName
    jmp Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo] , 1
    jmp Lable_Search_In_Root_Dir_Begin
