package kernel

@(default_calling_convention = "sysv")
foreign _ {
	cpu_enable_sse :: proc() ---
	cpu_port_write_byte :: proc(port: u16, data: u8) ---
	cpu_halt_forever :: proc() -> ! ---
}
