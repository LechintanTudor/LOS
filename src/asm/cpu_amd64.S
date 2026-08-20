#define IA32_EFER 0xC0000080
#define EFER_NXE (1 << 11)

.section .text

.extern int_amd64_handle_interrupt

.global cpu_init
.type cpu_init @function
cpu_init:
    # Bit 1: Enable Monitor co-processor.
    # Bit 2: Disable x87 FPU Emulation.
    movq %cr0, %rax
    orq $(1 << 1), %rax
    andq $~(1 << 2), %rax
    movq %rax, %cr0

    # Bit 9: Enable the FXSAVE and FXRSTOR instructions.
    movq %cr4, %rax
    orq $(1 << 9), %rax
    movq %rax, %cr4

    # Bit 11: Enable the Execute Disable bit.
    movl $IA32_EFER, %ecx
    rdmsr
    orl $EFER_NXE, %eax
    wrmsr

    ret

.global cpu_port_write_byte
.type cpu_port_write_byte @function
cpu_port_write_byte:
    movw %di, %dx
    movb %sil, %al
    outb %al, %dx
    ret

.global cpu_send_interrupt_100
.type cpu_send_interrupt_100 @function
cpu_send_interrupt_100:
    int $0x64
    ret

.global cpu_handle_interrupt_100
.type cpu_handle_interrupt_100 @function
cpu_handle_interrupt_100:
    pushq $67  // Error
    pushq $100 // Vector
    jmp cpu_handle_interrupt_common

.global cpu_handle_interrupt_common
.type cpu_handle_interrupt_common @function
cpu_handle_interrupt_common:
    pushq %r15
    pushq %r14
    pushq %r13
    pushq %r12
    pushq %r11
    pushq %r10
    pushq %r9
    pushq %r8
    pushq %rbp
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %rbx
    pushq %rax

    cld
    movq %rsp, %rdi
    call int_amd64_handle_interrupt

    popq %rax
    popq %rbx
    popq %rcx
    popq %rdx
    popq %rsi
    popq %rdi
    popq %rbp
    popq %r8
    popq %r9
    popq %r10
    popq %r11
    popq %r12
    popq %r13
    popq %r14
    popq %r15

    addq $16, %rsp
    iretq
