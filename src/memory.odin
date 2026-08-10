package kernel

hhdm_base: uintptr

Physical_Address :: distinct uintptr

Virtual_Address :: distinct uintptr

Mapping_Flags :: bit_set[Mapping_Flags_Bits;u64]

Mapping_Flags_Bits :: enum {
	Read,
	Write,
	Execute,
	User,
}
