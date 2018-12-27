; Working with VGA modes
; Written to NASM 2.14, and tested under DOSBox 0.74
;
; Derived from listing 23-1 of Michael Abrash's Graphics Programming Black Book.
;
; By Stephen Horn

;-------------------------------------
;
;  Defines
;
;-------------------------------------

;
; Memory offsets
;

VIDEO_SEGMENT       equ 0a000h  ; Displayed VGA memory maps to this address

VIDEO_BUFFER_WIDTH  equ 640/8 ;672/8   ; Width in bytes
VIDEO_BUFFER_HEIGHT equ 350 ;384     ; Height in scanlines

PAGE0_OFFSET        equ 0
PAGE1_OFFSET        equ (VIDEO_BUFFER_WIDTH * VIDEO_BUFFER_HEIGHT)
BALL_OFFSET         equ PAGE1_OFFSET * 2
BLANK_OFFSET        equ BALL_OFFSET + 8

;
; VGA registers
;

; Attribute Controller
AC_INDEX_DATA_REG           equ 03C0h

; CRT Controller
CRTC_INDEX_COLOR_REG        equ 3D4h
CRTC_DATA_COLOR_REG         equ 3D5h
CRTC_INDEX_MONO_REG         equ 3B4h
CRTC_DATA_MONO_REG          equ 3B5h

; Sequence Controller
SC_INDEX_REG                equ 3C4h
SC_DATA_REG                 equ 3C5h

; Graphics Controller
GC_INDEX_REG                equ 3CEh
GC_DATA_REG                 equ 3CFh

; Others
INPUT_STATUS_1_COLOR_REG    equ 03DAh   ; read from this to reset AC index/data to index
INPUT_STATUS_1_MONO_REG     equ 03BAh   ; read from this to reset AC index/data to index

;
; VGA register indices
;

CRTC_OFFSET                 equ 19      ; 13h
CRTC_START_ADDRESS_LOW      equ 13      ; 0Dh
CRTC_START_ADDRESS_HIGH     equ 12      ; 0Ch

SC_MAP_MASK                 equ 2

GC_SET_RESET                equ 0
GC_ENABLE_SET_RESET         equ 1
GC_MODE                     equ 5

;
; VGA modes
;

; "True" graphical modes
;
VGA_MODE_320x200            equ 00Dh
VGA_MODE_640x200            equ 00Eh
VGA_MODE_640x350            equ 010h
VGA_MODE_640x480            equ 012h    ; Note that there isn't enough VGA memory for double-buffering in this mode

; "Mode X"
;
VGA_MODE_X                          equ 13h

;
; Status bits from status register 1
;
INPUT_STATUS_1_DISPLAY_ENABLED      equ 01h
INPUT_STATUS_1_VSYNC                equ 08h

;-------------------------------------
;
;  Macros
;
;-------------------------------------
org 100h

section .text

;
; Assert that a given comparison %1 resulted in equality, else exit and print string %2
;
%macro ASSERT 3                     ; Uses ax, dx; but only if assert is triggered
    %1
    %2 %%no_assert
    jmp %%assert

    section .data
        %%message: db %3, '$'

    section .text

    %%assert:
        mov ax, 3   ; reset to text mode display
        int 10h;

        mov dx, %%message

        mov ah, 09h ; Display $-terminated string in dx
        int 21h

        int3

        mov ah, 4Ch  ; exit back to DOS
        int 21h

    %%no_assert:
%endmacro

;
; Macro to set register P1, index P2 to value P3.
;
%macro SET_VGA_REGISTER 3           ; Uses ax, dx
    %ifidni %3, ax
        %error "SET_VGA_REGISTER requires register ax, but ax was specified as value"
    %endif
    %ifidni %3, al
        %error "SET_VGA_REGISTER requires register ax, but al was specified as value"
    %endif
    %ifidni %3, dx
        %error "SET_VGA_REGISTER requires register dx, but dx was specified as value"
    %endif

    mov dx, %1
    mov al, %2
    %if %1 == AC_INDEX_DATA_REG     
        out dx, al                  ; The AC index/data register is different from the
        mov al, %3                  ; others, in that it toggles from index to data
        out dx, al                  ; and thus requires two byte outs to the same address.
    %else
        %ifidni %3, ah              
        %else                       ; Though it would be "normal" to do two byte outs
            mov ah, %3              ; anyways, we can take a shortcut and do a word
        %endif                      ; out, because the high byte will go to the register
        out dx, ax                  ; index + 1.
    %endif
%endmacro

;
; Macro to modify register P1, index P2 by turning off bits P3 and then setting bits P4.
;
%macro MODIFY_VGA_REGISTER 4        ; Uses ax, dx
    %ifidni %3, ax
        %error "MODIFY_VGA_REGISTER requires register ax, but ax was specified as value"
    %endif
    %ifidni %3, al
        %error "MODIFY_VGA_REGISTER requires register ax, but al was specified as value"
    %endif
    %ifidni %3, dx
        %error "MODIFY_VGA_REGISTER requires register dx, but dx was specified as value"
    %endif
    %ifidni %4, ax
        %error "MODIFY_VGA_REGISTER requires register ax, but ax was specified as value"
    %endif
    %ifidni %4, al
        %error "MODIFY_VGA_REGISTER requires register ax, but al was specified as value"
    %endif
    %ifidni %4, dx
        %error "MODIFY_VGA_REGISTER requires register dx, but dx was specified as value"
    %endif

    ; Set VGA register %1 to index %2
    mov dx, %1
    mov al, %2
    out dx, al
    inc dx          ; The data register is on the next port value
    jmp $+2         ; This is a delay to let the bus settle
    in al, dx
    %ifnum %3
        and al, ~%3
    %else
        not %3
        and al, %3
        not %3
    %endif
    or al, %4
    jmp $+2         ; According to my sample code (Abrash listing 23-1), this delay is also needed to let the bus settle.
    out dx, al
%endmacro

;
; Macro to reset the AC index/data register to index-mode
;
%macro RESET_AC_INDEX_DATA_REG 0    ; Uses ax, dx

    mov dx, INPUT_STATUS_1_COLOR_REG
    in  al, dx

%endmacro

;-------------------------------------
;
;  Main function
;
;-------------------------------------

start:
    ;
    ; Set video mode to 010h (640x350 VGA)
    ;
    mov ax, VGA_MODE_640x350 ;VGA_MODE_640x200; VGA_MODE_640x350
    int 10h

    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; Set the logical screen width
    SET_VGA_REGISTER CRTC_INDEX_COLOR_REG, CRTC_OFFSET, (VIDEO_BUFFER_WIDTH / 2)

    ; Draw borders on both pages
    push bx

    mov bx, 0D0Fh; 0C0Eh
    mov di, PAGE0_OFFSET
    call draw_border

    mov bx, 0D0Fh
    mov di, PAGE1_OFFSET
    call draw_border

    pop bx

    SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, 0fh
    mov al, 0
    mov di, BALL_OFFSET
    mov cx, 8*2
    rep stosb

    ;MODIFY_VGA_REGISTER GC_INDEX_REG, GC_MODE, 0bh, 00h | 00h
    ;SET_VGA_REGISTER GC_INDEX_REG, GC_ENABLE_SET_RESET, 01h
    ;SET_VGA_REGISTER GC_INDEX_REG, GC_SET_RESET, 01h
    SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, 01h ; Blue plane
    mov si, BallPlane0Image
    mov di, BALL_OFFSET
    mov cx, 8
    rep movsb

    ;SET_VGA_REGISTER GC_INDEX_REG, GC_ENABLE_SET_RESET, 02h
    ;SET_VGA_REGISTER GC_INDEX_REG, GC_SET_RESET, 02h
    SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, 02h ; Green plane
    mov si, BallPlane0Image
    mov di, BALL_OFFSET
    mov cx, 8
    rep movsb

    ; SET_VGA_REGISTER GC_INDEX_REG, GC_SET_RESET, 08h
    ; SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, 08h ; Intensity plane
    ; mov si, BallPlane0Image
    ; mov di, BALL_OFFSET
    ; mov cx, 8
    ; rep movsb

    ;SET_VGA_REGISTER GC_INDEX_REG, GC_ENABLE_SET_RESET, 0fh
    ;SET_VGA_REGISTER GC_INDEX_REG, GC_SET_RESET, 0fh
    MODIFY_VGA_REGISTER GC_INDEX_REG, GC_MODE, 03h, 01h

.main_loop:

    push bp
    mov bp, NUM_BALLS * 2 - 2
    .erase_balls:
        mov si, BLANK_OFFSET
        mov cx, word [Ball_last_pos_x + bp]
        mov dx, word [Ball_last_pos_y + bp]

        ; All ball positions have been premultiplied by 1 << 4 so that we can represent sub-pixel movement
        ; So cast back to pixel coordinates before erasing
        shr cx, 4
        shr dx, 4

        call draw_ball

        dec bp
        dec bp
        jns .erase_balls

    mov bp, NUM_BALLS * 2 - 2
    .update_balls:
        mov cx, word [Ball_pos_x + bp]
        mov word [Ball_last_pos_x + bp], cx
        mov dx, word [Ball_pos_y + bp]
        mov word [Ball_last_pos_y + bp], dx

        ; Apply the ball's acceleration to its velocity,
        ; and its consequent velocity to its position
        mov ax, word [Ball_vel_x + bp]
        add ax, word [Ball_accel_x + bp]
        mov bx, ax
        add ax, cx

        ; If the ball is about to move out-of-bounds,
        ; set its position to the boundary edge and
        ; negate its velocity
        cmp ax, (VIDEO_BUFFER_WIDTH-1) << 4
        jl .within_right_boundary
            mov ax, (VIDEO_BUFFER_WIDTH-2) << 4
            neg bx
        .within_right_boundary:
        cmp ax, (1 << 4) - 1
        jg .within_left_boundary
            mov ax, 1 << 4
            neg bx
        .within_left_boundary:
        mov word [Ball_pos_x + bp], ax
        mov word [Ball_vel_x + bp], bx
        mov cx, ax

        ;; Now the same thing for the y component

        mov ax, word [Ball_vel_y + bp]
        add ax, word [Ball_accel_y + bp]
        mov bx, ax
        add ax, dx

        cmp ax, (VIDEO_BUFFER_HEIGHT-15) << 4
        jl .within_bottom_boundary
            mov ax, (VIDEO_BUFFER_HEIGHT-16) << 4
            neg bx
        .within_bottom_boundary:
        cmp ax, 7 << 4
        jg .within_top_boundary
            mov ax, 8 << 4
            neg bx
        .within_top_boundary:
        mov word [Ball_pos_y + bp], ax
        mov word [Ball_vel_y + bp], bx
        mov dx, ax

        ; All ball positions have been premultiplied by 1 << 4 so that we can represent sub-pixel movement
        ; So cast back to pixel coordinates before erasing
        shr cx, 4
        shr dx, 4

        mov si, BALL_OFFSET
        call draw_ball

        dec bp
        dec bp
        jns .update_balls

    pop bp
    
    call wait_for_display_enable

    ; Page flipping, part 1 (set page we were drawing on to be the displayed VGA page)
    SET_VGA_REGISTER CRTC_INDEX_COLOR_REG, CRTC_START_ADDRESS_LOW, [Current_page_offset]
    SET_VGA_REGISTER CRTC_INDEX_COLOR_REG, CRTC_START_ADDRESS_HIGH, [Current_page_offset+1]

    call wait_for_vsync

; If we were doing horizontal panning, here would be a grand spot to do that, just as the
; new visible page address takes effect.

    ; Page flipping, part 2 (update the page we're drawing to)
    xor byte [Current_page], 1
    jnz .flip_to_1
    .flip_to_0:
        mov word [Current_page_offset], PAGE0_OFFSET
        jmp .done_flipping
    .flip_to_1:
        mov word [Current_page_offset], PAGE1_OFFSET
    .done_flipping:

    ;
    ; Exit if a key's been hit
    ;
    mov ah, 1
    int 16h
    jz .main_loop

    mov ah, 0   ; Clear the keypress
    int 16h

    mov ax, 3   ; reset to text mode display
    int 10h;

    mov ah, 4Ch  ; exit back to DOS
    int 21h

;-------------------------------------
;
;  Other Functions
;
;-------------------------------------


wait_for_vsync:
    mov dx, INPUT_STATUS_1_COLOR_REG
    .wait1:
        in al, dx
        and al, INPUT_STATUS_1_VSYNC
        jnz .wait1
    .wait2:
        in al, dx
        and al, INPUT_STATUS_1_VSYNC
        jz .wait2
    ret    

wait_for_display_enable:
    mov dx, INPUT_STATUS_1_COLOR_REG
    .wait1:
        in al, dx
        and al, INPUT_STATUS_1_DISPLAY_ENABLED
        jnz .wait1
    ret

;-------------------------------------
;
;  Drawing Functions
;
;-------------------------------------


draw_ball:
    ; We expect the ball data to be pointed to by si
    ; We expect the ball's x position to be cx
    ; We expect the ball's y position to be dx
    mov ax, VIDEO_BUFFER_WIDTH
    mul dx
    add ax, cx
    add ax, word [Current_page_offset]

    push di
    push bp
    push ds

    mov di, ax  ; Our write offset into video memory
    mov bp, 8   ; Height of the ball in scanlines
    push es     ; We won't be modifying es, but this conveniently puts VIDEO_SEGMENT somewhere we can reach it
    pop ds      ; ...because we're setting ds to VIDEO_SEGMENT
    .draw_loop:
        push di     ; Copy the write offset starting position to stack
        mov cx, 1
        rep movsb   ; Copy ds:si to es:di
        pop di
        add di, VIDEO_BUFFER_WIDTH
        dec bp
        jnz .draw_loop
    pop ds
    pop bp
    pop di
    ret

draw_border:
    push di
    
    mov cx, VIDEO_BUFFER_HEIGHT / 16
    .left_side:
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bl; 0Ch     ; Setting draw color to red
        call draw_box_8x8

        add di, VIDEO_BUFFER_WIDTH * 8

        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bh; 0Eh     ; Setting draw color to yellow
        call draw_box_8x8

        add di, VIDEO_BUFFER_WIDTH * 8

        loop .left_side

    pop di
    push di

    add di, VIDEO_BUFFER_WIDTH - 1
    mov cx, VIDEO_BUFFER_HEIGHT / 16
    .right_side:
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bl; 0Ch     ; Setting draw color to red
        call draw_box_8x8

        add di, VIDEO_BUFFER_WIDTH * 8

        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bh; 0Eh     ; Setting draw color to yellow
        call draw_box_8x8

        add di, VIDEO_BUFFER_WIDTH * 8

        loop .right_side

    pop di
    push di
    mov cx, (VIDEO_BUFFER_WIDTH - 2) / 2
    .top_side:
        inc di
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bh; 0Eh     ; Color yellow
        call draw_box_8x8

        inc di
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bl; 0Ch     ; Color red
        call draw_box_8x8

        loop .top_side

    pop di

    add di, (VIDEO_BUFFER_HEIGHT - 8) * VIDEO_BUFFER_WIDTH
    mov cx, (VIDEO_BUFFER_WIDTH - 2) / 2
    .bottom_side:
        inc di
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bh; 0Eh     ; Color yellow
        call draw_box_8x8

        inc di
        SET_VGA_REGISTER SC_INDEX_REG, SC_MAP_MASK, bl; 0Ch     ; Color red
        call draw_box_8x8

        loop .bottom_side

    ret

draw_box_8x8:
    push di

    mov al, 0FFh
    %rep 8
        stosb
        add di, VIDEO_BUFFER_WIDTH-1
    %endrep
    pop di
    ret


;-------------------------------------
;
;  Global variables
;
;-------------------------------------
section .data

Current_page:           db 0
Current_page_offset:    dw 0

NUM_BALLS               equ 4

Ball_pos_x:             dw 2 << 4,      8 << 4,     22 << 4,    33 << 4
Ball_pos_y:             dw 26 << 4,     89 << 4,    160 << 4,   206 << 4

Ball_last_pos_x:        dw 2 << 4,      8 << 4,     22 << 4,    33 << 4
Ball_last_pos_y:        dw 26 << 4,     89 << 4,    160 << 4,   206 << 4

Ball_vel_x:             dw 10,          8,         -16,        14
Ball_vel_y:             dw 0,           0,          0,          0

Ball_accel_x:           dw 0,           0,          0,          0
Ball_accel_y:           dw 10,          9,          8,          7

BallPlane0Image:    ; blue plane
db  03Ch
db  07Eh
db  0FFh
db  0FFh
db  0FFh
db  0FFh
db  07Eh
db  03Ch


section .bss
