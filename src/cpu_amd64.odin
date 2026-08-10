package kernel

@(default_calling_convention = "sysv")
foreign _ {
	cpu_init :: proc() ---

	@(require_results)
	cpu_get_cr3 :: proc() -> uintptr ---

	cpu_set_cr3 :: proc(value: uintptr) ---

	cpu_port_write_byte :: proc(port: u16, data: u8) ---

	cpu_halt_forever :: proc() -> ! ---
}
