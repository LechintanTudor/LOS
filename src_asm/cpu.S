.section .text

.global cpu_enable_sse
.type cpu_enable_sse @function
cpu_enable_sse:
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
