package kernel

// 4-level paging:
// 1. pdpt = pml4[pml4_index]
// 2. pd = pdpt[pdpt_index]
// 3. pt = pd[pd_index]
// 4. page = pt[pt_index]
Address_Space :: struct {
	pml4: ^Address_Table,
}

Address_Table :: distinct [512]Address_Entry

Address_Entry :: distinct uintptr

Address_Flags :: bit_set[Address_Flags_Bits;uintptr]

Address_Flags_Bits :: enum {
	Present    = 0,
	Write      = 1,
	User       = 2,
	Global     = 8,
	No_Execute = 63,
}

@(require_results)
address_flags_from_mapping_flags :: #force_inline proc "contextless" (
	mapping_flags: Mapping_Flags,
) -> (
	address_flags: Address_Flags,
) {
	address_flags += {.Present}

	if .Write in mapping_flags {
		address_flags += {.Write}
	}

	if .Execute not_in mapping_flags {
		address_flags += {.No_Execute}
	}

	if .User in mapping_flags {
		address_flags += {.User}
	}

	return
}

// Get the PML4 (Page Map Level 4) index from a virtual address.
@(require_results)
address_get_pml4 :: #force_inline proc "contextless" (address: Virtual_Address) -> int {
	return int((address >> 39) & 0x1ff)
}

// Get the PDPT (Page Directory Pointer Table) index from a virtual address.
@(require_results)
address_get_pdpt :: #force_inline proc "contextless" (address: Virtual_Address) -> int {
	return int((address >> 30) & 0x1ff)
}

// Get the PD (Page Directory) index from a virtual address.
@(require_results)
address_get_pd :: #force_inline proc "contextless" (address: Virtual_Address) -> int {
	return int((address >> 21) & 0x1ff)
}

// Get the PT (Page Table) index from a virtual address.
@(require_results)
address_get_pt :: #force_inline proc "contextless" (address: Virtual_Address) -> int {
	return int((address >> 12) & 0x1ff)
}
