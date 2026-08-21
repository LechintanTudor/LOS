package kernel

INTR_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN :: 256

INTR_AMD64_ATTRIBUTE_INTERRUPT :: 0x8e

INTR_AMD64_ATTRIBUTE_TRAP :: 0x8f

intr_amd64_interrupt_descriptor_table: [INTR_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN]INTR_AMD64_Interrupt_Descriptor

INTR_AMD64_Interrupt_Descriptor :: struct {
	// ISR address bits 0 ..< 16.
	isr_address_0: u16,

	// Segment selector.
	selector:      u16,

	// IST offset bits 0 ..< 3.
	ist_offset:    u8,

	// Gate type, privillege level, present.
	attributes:    u8,

	// ISR address bits 16 ..< 32.
	isr_address_1: u16,

	// ISR address bits 32 ..< 64.
	isr_address_2: u32,

	// Reserved, should be zero.
	reserved:      u32,
}

INTR_AMD64_Interrupt_Descriptor_Table_Register :: struct #packed {
	limit: u16,
	base:  uintptr,
}

INTR_AMD64_Interrupt_Frame :: struct {
	// Saved registers.
	rax:    u64,
	rbx:    u64,
	rcx:    u64,
	rdx:    u64,
	rsi:    u64,
	rdi:    u64,
	rbp:    u64,
	r8:     u64,
	r9:     u64,
	r10:    u64,
	r11:    u64,
	r12:    u64,
	r13:    u64,
	r14:    u64,
	r15:    u64,

	// Interrupt info.
	vector: u64,
	error:  u64,

	// CPU state.
	rip:    u64,
	cs:     u64,
	rflags: u64,
	rsp:    u64,
	ss:     u64,
}

intr_amd64_init :: proc "contextless" () {
	for &descriptor, i in intr_amd64_interrupt_descriptor_table {
		descriptor = intr_amd64_interrupt_descriptor_create(cpu_interrupt_handlers[i])
	}

	idtr := INTR_AMD64_Interrupt_Descriptor_Table_Register {
		limit = size_of(intr_amd64_interrupt_descriptor_table) - 1,
		base  = uintptr(&intr_amd64_interrupt_descriptor_table),
	}

	cpu_enable_interrupts(&idtr)
}

@(require_results)
intr_amd64_interrupt_descriptor_create :: proc "contextless" (
	isr: rawptr,
) -> (
	descriptor: INTR_AMD64_Interrupt_Descriptor,
) {
	isr := uintptr(isr)
	descriptor.isr_address_0 = u16(isr & U16_MAX)
	descriptor.isr_address_1 = u16((isr >> 16) & U16_MAX)
	descriptor.isr_address_2 = u32((isr >> 32) & U32_MAX)

	descriptor.selector = 0x28
	descriptor.attributes = INTR_AMD64_ATTRIBUTE_INTERRUPT
	return
}

@(export)
intr_amd64_handle_interrupt :: proc "contextless" (frame: ^INTR_AMD64_Interrupt_Frame) {
	fmt_buf: [128]byte = ---
	fmt := fmt_create(fmt_buf[:])
	fmt_write(&fmt, "Vector: ")
	fmt_write(&fmt, frame.vector)
	fmt_write(&fmt, ", Error: ")
	fmt_write(&fmt, frame.error)
	log_info(fmt_get(fmt))
}
