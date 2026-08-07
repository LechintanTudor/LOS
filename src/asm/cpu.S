#define IA32_EFER 0xC0000080
#define EFER_NXE (1 << 11)

.section .text

.global cpu_init
.type cpu_init @function
cpu_init:
    # Bit 1: Enable Monitor co-processor.
    # Bit 2: Disable x87 FPU Emulation.
    movq %cr0, %rax
    orq $(1 << 1), %rax
    andq $~(1 << 2), %rax
    movq %rax, %cr0

    # Bit 9:  Enable the FXSAVE and FXRSTOR instructions.
    # Bit 10: Enable Unmasked SIMD Floating-Point Exceptions.
    movq %cr4, %rax
    orq $((1 << 9) | (1 << 10)), %rax
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

.global cpu_halt_forever
.type cpu_halt_forever @function
cpu_halt_forever:
    cli

    1:
        hlt
        jmp 1b
