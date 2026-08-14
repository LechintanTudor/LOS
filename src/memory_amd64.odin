package kernel

VM_AMD64_PAGE_TABLE_LEN :: 512
VM_AMD64_PAGE_TABLE_HALF_LEN :: VM_AMD64_PAGE_TABLE_LEN / 2

// 4-level paging:
// 1. pdpt = pml4[pml4_index]
// 2. pd = pdpt[pdpt_index]
// 3. pt = pd[pd_index]
// 4. page = pt[pt_index]
VM_AMD64_Page_Table :: distinct [VM_AMD64_PAGE_TABLE_LEN]VM_AMD64_Page_Table_Entry

VM_AMD64_Page_Table_Entry :: distinct uintptr

VM_AMD64_Flags :: bit_set[VM_AMD64_Flags_Bits;uintptr]

VM_AMD64_Flags_Bits :: enum {
	Present    = 0,
	Write      = 1,
	User       = 2,
	Global     = 8,
	No_Execute = 63,
}

@(require_results)
vm_amd64_convert_flags :: #force_inline proc "contextless" (
	flags: VM_Flags,
) -> (
	converted_flags: VM_AMD64_Flags,
) {
	converted_flags += {.Present, .User}

	if .Write in flags {
		converted_flags += {.Write}
	}

	if .Execute not_in flags {
		converted_flags += {.No_Execute}
	}

	return
}

@(require_results)
vm_amd64_get_page_table_physical_address :: #force_inline proc "contextless" (
	cr3: uintptr,
) -> VM_Physical_Address {
	return VM_Physical_Address(cr3 & ~uintptr(PAGE_MASK))
}

// Get the PML4 (Page Map Level 4) index from a virtual address.
@(require_results)
vm_amd64_get_pml4 :: #force_inline proc "contextless" (address: VM_Virtual_Address) -> int {
	return int((address >> 39) & 0x1ff)
}

// Get the PDPT (Page Directory Pointer Table) index from a virtual address.
@(require_results)
vm_amd64_get_pdpt :: #force_inline proc "contextless" (address: VM_Virtual_Address) -> int {
	return int((address >> 30) & 0x1ff)
}

// Get the PD (Page Directory) index from a virtual address.
@(require_results)
vm_amd64_get_pd :: #force_inline proc "contextless" (address: VM_Virtual_Address) -> int {
	return int((address >> 21) & 0x1ff)
}

// Get the PT (Page Table) index from a virtual address.
@(require_results)
vm_amd64_get_pt :: #force_inline proc "contextless" (address: VM_Virtual_Address) -> int {
	return int((address >> 12) & 0x1ff)
}
