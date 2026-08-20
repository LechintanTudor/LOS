package kernel

@(default_calling_convention = "sysv")
foreign _ {
	cpu_interrupt_handlers: [INT_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN]rawptr

	cpu_init :: proc() ---

	cpu_port_write_byte :: proc(port: u16, data: byte) ---

	cpu_send_interrupt_100 :: proc() ---

	cpu_handle_interrupt_100 :: proc() ---
}

cpu_enable_interrupts :: asm(idtr: ^Int_AMD64_Interrupt_Descriptor_Table_Register) {
    lidt [idtr]
    sti
}

cpu_set_cr3 :: asm(cr3: u64) [#volatile] {
	mov %cr3, cr3
}

@(require_results)
cpu_get_cr3 :: asm() -> (cr3: u64) {
	mov cr3, %cr3
}

cpu_halt_and_catch_fire :: asm() -> ! {
	cli

	.loop:
		hlt
		jmp .loop
}
