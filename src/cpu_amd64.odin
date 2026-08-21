package kernel

@(default_calling_convention = "sysv")
foreign _ {
	cpu_amd64_interrupt_handlers: [INTR_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN]rawptr

	cpu_amd64_init :: proc() ---

	cpu_amd64_port_write_byte :: proc(port: u16, data: byte) ---

	cpu_amd64_send_interrupt_100 :: proc() ---

	cpu_amd64_handle_interrupt_100 :: proc() ---
}

cpu_amd64_enable_interrupts :: asm(idtr: ^INTR_AMD64_Interrupt_Descriptor_Table_Register) {
    lidt [idtr]
    sti
}

cpu_amd64_set_cr3 :: asm(cr3: u64) [#volatile] {
	mov %cr3, cr3
}

@(require_results)
cpu_amd64_get_cr3 :: asm() -> (cr3: u64) {
	mov cr3, %cr3
}

cpu_halt_and_catch_fire :: asm() -> ! {
	cli

	.loop:
		hlt
		jmp .loop
}
