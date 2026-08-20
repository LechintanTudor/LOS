#define IA32_EFER 0xC0000080
#define EFER_NXE (1 << 11)

.intel_syntax noprefix

.section .text

.extern int_amd64_handle_interrupt

.global cpu_init
.type cpu_init @function
cpu_init:
    # Bit 1: Enable Monitor co-processor.
    # Bit 2: Disable x87 FPU Emulation.
    mov rax, cr0
    or rax, 1 << 1
    and rax, ~(1 << 2)
    mov cr0, rax

    # Bit 9: Enable the FXSAVE and FXRSTOR instructions.
    mov rax, cr4
    or rax, 1 << 9
    mov cr4, rax

    # Bit 11: Enable the Execute Disable bit.
    mov ecx, IA32_EFER
    rdmsr
    or eax, EFER_NXE
    wrmsr

    ret

.global cpu_port_write_byte
.type cpu_port_write_byte @function
cpu_port_write_byte:
    mov dx, di
    mov al, sil
    out dx, al
    ret

.global cpu_send_interrupt_100
.type cpu_send_interrupt_100 @function
cpu_send_interrupt_100:
    int 100
    ret

.global cpu_handle_interrupt_common
.type cpu_handle_interrupt_common @function
cpu_handle_interrupt_common:
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rbp
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax

    cld
    mov rdi, rsp
    call int_amd64_handle_interrupt

    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rbp
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15

    add rsp, 16
    iretq
