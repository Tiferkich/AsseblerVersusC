bits 64
section .data
M_PI dq 3.14159265358979323846264338327950288419716939937510

global work_image_asm

section .text

extern cos
extern sin
extern printf
extern round



cosin equ 8
sinus equ cosin+8
rad equ sinus+8
xc equ rad+8
yc equ xc+8
width equ yc+8
height equ width+8
channels equ height+8
;cx_dst equ channels+8
;cy_dst equ cx_dst+8
;dst_width equ cy_dst+8
;dst_height equ dst_width+8

work_image_asm:
    ; Function arguments
    ; rdi - src
    ; rsi - dst
    ; rdx - width
    ; rcx - height
    ; r8  - channels
    ; r9  - angle
	; r10 - src-height
	; r11 - src-weight
	;mov r10,[rbp+32]
	;mov r11,[rbp+16]
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbp,rsp
    sub rsp,channels
    ;and rsp,-16
	;mov [rbp-dst_width],r11
	;mov [rbp-dst_height],r10
	
    ; cx = width / 2
    mov rax, rdx
    shr rax, 1               
    mov [rbp-xc], rax              

  	;cy = height / 2
    mov rax, rcx
    shr rax, 1                
    mov [rbp-yc], rax    

    ;mov rax, r11
    ;shr rax, 1                
    ;mov [rbp-cx_dst], rax    

    ;mov rax, r10
    ;shr rax, 1                
    ;mov [rbp-cy_dst], rax        
    
	
    ;rad = angle * M_PI / 180.0
    cvtsi2sd xmm0, r9          
    mov rax, M_PI              
    movq xmm1, [rax]           
    mulsd xmm0, xmm1           ; xmm0 = angle * M_PI
    mov rax, 180
    cvtsi2sd xmm1, rax         ; Load 180.0 into xmm1
    divsd xmm0, xmm1           ; xmm0 = angle * M_PI / 180.0
	movsd [rbp-rad],xmm0
	mov [rbp-height],rcx
	mov [rbp-width], rdx
	mov [rbp-channels],r8


	push rdi
	push rsi
    call cos                  ; cos(rad)
	movsd [rbp-cosin],xmm0
	   ; xmm2 = cos(rad)
    movsd xmm0, [rbp-rad]
    call sin                  ; sin(rad)
    movsd [rbp-sinus],xmm0         ; xmm3 = sin(rad)

	pop rsi
	pop rdi

	

    xor r12, r12              ; y = 0

y_loop:
    xor r13, r13              ; x = 0

x_loop:

    ; newX = (cos_angle * (x - cx) - sin_angle * (y - cy)) + cx;
    ; newY = (sin_angle * (x - cx) + cos_angle * (y - cy)) + cy;
	
    mov rax, r13
    sub rax, [rbp-xc]
    
    cvtsi2sd xmm0, rax        ; xmm0 = (x - cx)
    
    mov rax, r12
    sub rax, [rbp-yc]
    cvtsi2sd xmm1, rax        ; xmm1 = (y - cy)
	
    movsd xmm4, xmm0
    mulsd xmm4, [rbp-cosin]          ; xmm4 = cos_angle * (x - cx)
    movsd xmm5, xmm1
    mulsd xmm5, [rbp-sinus]          ; xmm5 = sin_angle * (y - cy)
    subsd xmm4, xmm5          ; xmm4 = cos_angle * (x - cx) - sin_angle * (y - cy)
	roundsd xmm4,xmm4,0
    cvttsd2si rax, xmm4
    
    add rax, [rbp-xc]              ; rax = newX
	

    mov rbx, rax

    movsd xmm4, xmm0
    mulsd xmm4, [rbp-sinus]          ; xmm4 = sin_angle * (x - cx)
    movsd xmm5, xmm1
    mulsd xmm5, [rbp-cosin]          ; xmm5 = cos_angle * (y - cy)
    addsd xmm4, xmm5          ; xmm4 = sin_angle * (x - cx) + cos_angle * (y - cy)
	roundsd xmm4,xmm4,0
    cvttsd2si rax, xmm4
    add rax, [rbp-yc]              ; rax = newY
    
    mov rcx, rax


    ;cmp rbx,0
    ;jb fill_zeroes            ; if (newX < 0)
    test rbx,rbx
    js fill_zeroes
    cmp rbx, [rbp-width]
    jge fill_zeroes            ; if (newX >= width)

    ;cmp rcx,0
    ;jb fill_zeroes             ; if (newY < 0)
    test rcx,rcx
    js fill_zeroes
    cmp rcx, [rbp-height]
    jge fill_zeroes            ; if (newY >= height)
;!!!!
	push rsi
	push rdi
	
	mov rax, r12
	imul rax,[rbp-width]
	add rax,r13
	imul rax, [rbp-channels]
	lea rsi, [rsi + rax]


	mov rax, rcx
	imul rax, [rbp-width]
	add rax, rbx
	imul rax, [rbp-channels]
	lea rdi, [rdi + rax] 
	

    mov rcx, [rbp-channels]
                
copy_channels:
    mov al, [rdi]
    mov [rsi], al
    inc rsi
    inc rdi
    loop copy_channels
  	pop rdi
  	pop rsi
    jmp next_pixel

fill_zeroes:

    mov rcx, [rbp-channels]
    push rsi
    mov rax, r12
	imul rax,[rbp-width]
	add rax,r13
	imul rax,[rbp-channels]
	lea rsi, [rax+rsi] 


zero_fill:
    mov byte [rsi], 0
    inc rsi
    loop zero_fill
	pop rsi

next_pixel:
    inc r13
    cmp r13, [rbp-width]
    jl x_loop
    
	
    inc r12
    cmp r12, [rbp-height]
    jl y_loop

	mov rsp,rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
	

   
    ret

