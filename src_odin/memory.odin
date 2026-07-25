package kernel

import "base:intrinsics"
import "extern:limine"

MEMORY_PAGE_SIZE :: 4096
MEMORY_PAGE_MASK :: MEMORY_PAGE_SIZE - 1

memory_pages: []Memory_Page
memory_hhdm_offset: uintptr

Memory_Page :: struct {
	flags: Memory_Page_Flags,
}

Memory_Page_Flags :: bit_set[Memory_Page_Flags_Bits;u32]

Memory_Page_Flags_Bits :: enum u32 {
	Used,
}

memory_init_from_limine :: proc "contextless" () {
	hhdm := intrinsics.volatile_load(&boot_hhdm_request.response)
	memory_hhdm_offset = uintptr(hhdm.offset)

	memmap := intrinsics.volatile_load(&boot_memmap_request.response)
	memmap_entries := memmap.entries[:memmap.entry_count]
	last_physical_address: uintptr

	// Find the last usable physical address and clamp the memap entries to it.
	#reverse for entry, i in memmap_entries {
		if entry.type == limine.MEMMAP_USABLE {
			last_physical_address = uintptr(entry.base + entry.length)
			memmap_entries = memmap_entries[:i + 1]
			break
		}
	}

	page_count := u64(last_physical_address / MEMORY_PAGE_SIZE)
	page_array_size := page_count * size_of(Memory_Page)

	// Find a suitable entry for the pages array.
	for entry in memmap_entries {
		if entry.type == limine.MEMMAP_USABLE && entry.length >= page_array_size {
			memory_pages_address := memory_hhdm_offset + uintptr(entry.base)
			memory_pages = ([^]Memory_Page)(memory_pages_address)[:page_count]
			break
		}
	}

	if memory_pages == nil {
		log_string("Failed to map memory_pages")
		return
	}

	last_page_index := u64(0)

	// Initialize the pages based on Limine's memory maps.
	for entry in memmap_entries {
		start := entry.base / MEMORY_PAGE_SIZE
		end := start + entry.length / MEMORY_PAGE_SIZE

		{ 	// Mark pages that don't appear in the entries as used.
			for &page in memory_pages[last_page_index:start] {
				page = {
					flags = {.Used},
				}
			}

			last_page_index = end
		}

		page_template := Memory_Page {
			flags = {} if entry.type == limine.MEMMAP_USABLE else {.Used},
		}

		for &page in memory_pages[start:end] {
			page = page_template
		}
	}

	{ 	// Mark the pages used to store the pages array as used.
		start_physical_address := uintptr(raw_data(memory_pages)) - memory_hhdm_offset

		end_physical_address :=
			start_physical_address + uintptr(len(memory_pages)) * size_of(Memory_Page)

		start := start_physical_address / MEMORY_PAGE_SIZE
		end := memory_align_up(end_physical_address) / MEMORY_PAGE_SIZE

		for &page in memory_pages[start:end] {
			page = {
				flags = {.Used},
			}
		}
	}
}

@(require_results)
memory_align_up :: proc "contextless" (address: uintptr) -> uintptr {
	return (address + MEMORY_PAGE_MASK) & ~uintptr(MEMORY_PAGE_MASK)
}
