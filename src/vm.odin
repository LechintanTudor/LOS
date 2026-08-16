package kernel

vm_hhdm: uintptr
vm_kernel_page_table: ^VM_AMD64_Page_Table

VM_Physical_Address :: distinct uintptr

VM_Virtual_Address :: distinct uintptr

VM_Address_Space :: struct {
	page_table:     ^VM_AMD64_Page_Table,
	address_ranges: [12]VM_Address_Range,
}

VM_Address_Range :: struct {
	start: VM_Virtual_Address,
	end:   VM_Virtual_Address,
	flags: VM_Flags,
}

VM_Flags :: bit_set[VM_Flags_Bits;u64]

VM_Flags_Bits :: enum {
	Read,
	Write,
	Execute,
}

@(require_results)
vm_init :: proc "contextless" (boot_info: Boot_Info) -> (ok: bool) {
	vm_hhdm = boot_info.hhdm

	vm_kernel_page_table = vm_pointer_from_physical_address(
		VM_AMD64_Page_Table,
		vm_amd64_get_page_table_physical_address(cpu_get_cr3()),
	)

	page_init(boot_info) or_return
	return true
}

@(require_results)
vm_address_space_create :: proc "contextless" () -> (address_space: VM_Address_Space) {
	copy(
		dst = address_space.page_table[VM_AMD64_PAGE_TABLE_HALF_LEN:],
		src = vm_kernel_page_table[VM_AMD64_PAGE_TABLE_HALF_LEN:],
	)

	return
}

@(require_results)
vm_pointer_from_physical_address :: #force_inline proc "contextless" (
	$T: typeid,
	address: VM_Physical_Address,
) -> ^T {
	return (^T)(vm_hhdm + uintptr(address))
}

@(require_results)
vm_address_range_is_empty :: #force_inline proc "contextless" (range: VM_Address_Range) -> bool {
	return range.end <= range.start
}
