package kernel

INT_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN :: 256

INT_AMD64_ATTRIBUTE_INTERRUPT :: 0x8e

INT_AMD64_ATTRIBUTE_TRAP :: 0x8f

int_amd64_interrupt_descriptor_table: [INT_AMD64_INTERRUPT_DESCRIPTOR_TABLE_LEN]Int_AMD64_Interrupt_Descriptor

Int_AMD64_Interrupt_Descriptor :: struct {
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

Int_AMD64_Interrupt_Descriptor_Table_Register :: struct #packed {
	limit: u16,
	base:  uintptr,
}

Int_AMD64_Interrupt_Frame :: struct {
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

int_amd64_init :: proc "contextless" () {
	int_amd64_interrupt_descriptor_table[100] = int_amd64_interrupt_descriptor_create(
		rawptr(cpu_handle_interrupt_100),
	)

	idtr := Int_AMD64_Interrupt_Descriptor_Table_Register {
		limit = size_of(int_amd64_interrupt_descriptor_table) - 1,
		base  = uintptr(&int_amd64_interrupt_descriptor_table),
	}

	cpu_amd64_enable_interrupts(&idtr)
}

@(require_results)
int_amd64_interrupt_descriptor_create :: proc "contextless" (
	isr: rawptr,
) -> (
	descriptor: Int_AMD64_Interrupt_Descriptor,
) {
	isr := uintptr(isr)
	descriptor.isr_address_0 = u16(isr & U16_MAX)
	descriptor.isr_address_1 = u16((isr >> 16) & U16_MAX)
	descriptor.isr_address_2 = u32((isr >> 32) & U32_MAX)

	descriptor.selector = 0x28
	descriptor.attributes = INT_AMD64_ATTRIBUTE_INTERRUPT
	return
}

@(export)
int_amd64_handle_interrupt :: proc "contextless" (frame: ^Int_AMD64_Interrupt_Frame) {
	fmt_buf: [128]byte = ---
	fmt := fmt_create(fmt_buf[:])
	fmt_string(&fmt, "Vector: ")
	fmt_int(&fmt, frame.vector)
	fmt_string(&fmt, ", Error: ")
	fmt_int(&fmt, frame.error)
	log_info(fmt_get(fmt))
}
