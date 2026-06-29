package kernel

log :: proc "contextless" (message: string) {
	QEMU_DEBUG_PORT :: 0xe9

	for byte in transmute([]u8)message {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	cpu_port_write_byte(QEMU_DEBUG_PORT, '\n')
}
