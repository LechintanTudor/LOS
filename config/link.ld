OUTPUT_FORMAT(elf64-x86-64)

ENTRY(kernel_main)

PHDRS {
    limine_requests PT_LOAD FLAGS((1 << 0));            /* Read */
    text            PT_LOAD FLAGS((1 << 0) | (1 << 2)); /* Read + Execute */
    rodata          PT_LOAD FLAGS((1 << 0));            /* Read */
    data            PT_LOAD FLAGS((1 << 0) | (1 << 1)); /* Read + Write */
}

SECTIONS {
    /* We are a higher half kernel. */
    . = 0xffffffff80000000;

    .limine_requests : {
        KEEP(*(.limine_requests_start))
        KEEP(*(.limine_requests))
        KEEP(*(.limine_requests_end))
    } :limine_requests

    . = ALIGN(CONSTANT(MAXPAGESIZE));

    text : {
        *(.text .text.*)
    } :text

    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    . = ALIGN(CONSTANT(MAXPAGESIZE));

    .data : {
        *(.data .data.*)
    } :data

    /* Must be the last thing mapped to :data. */
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /* May cause issues on some hosts if not discarded. */
    /DISCARD/ : {
        *(.eh_frame)
        *(.note .note.*)
    }
}
