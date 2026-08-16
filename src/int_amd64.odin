package kernel

import "core:math/bits"

INT_AMD64_DESCRIPTOR_TABLE_LEN :: 256

INT_AMD64_GATE_TYPE_INTERRUPT :: 0xe

INT_AMD64_GATE_TYPE_TRAP :: 0xf

INT_AMD64_PRESENT :: 1 << 7

Int_AMD64_Descriptor_Table :: [INT_AMD64_DESCRIPTOR_TABLE_LEN]Int_AMD64_Descriptor

Int_AMD64_Descriptor :: struct {
	// ISR address bits 0 ..< 16.
	isr_address_0:   u16,

	// TODO: Segment selector.
	selector:        u16,

	// IST offset bits 0 ..< 3.
	ist_offset:      u8,

	// Gate type, privillege level, present.
	type_attributes: u8,

	// ISR address bits 16 ..< 32.
	isr_address_1:   u16,

	// ISR address bits 32 ..< 64.
	isr_address_2:   u32,

	// Reserved, should be zero.
	reserved:        u32,
}

@(require_results)
int_amd64_interrupt_descriptor_create :: proc "contextless" (
	isr: rawptr,
) -> (
	descriptor: Int_AMD64_Descriptor,
) {
	isr := uintptr(isr)
	descriptor.isr_address_0 = u16(isr & bits.U16_MAX)
	descriptor.isr_address_1 = u16((isr >> 16) & bits.U16_MAX)
	descriptor.isr_address_2 = u32((isr >> 32) & bits.U32_MAX)

	descriptor.type_attributes = INT_AMD64_GATE_TYPE_INTERRUPT | INT_AMD64_PRESENT
	return
}
