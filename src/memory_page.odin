package kernel

import "core:math/bits"
import "core:mem"
import "extern:limine"

PAGE_SIZE :: 4096
PAGE_MASK :: PAGE_SIZE - 1

page_allocator: Page_Allocator

Page :: struct {
	node:  List_Node,
	order: Page_Order,
	flags: Page_Flags,
}

Page_Order :: distinct u32

Page_Flags :: bit_set[Page_Flags_Bits;u32]

Page_Flags_Bits :: enum u32 {
	Free_Head,
}

@(require_results)
page_init :: proc "contextless" (boot_info: Boot_Info) -> (ok: bool) {
	hhdm_base = boot_info.hhdm_base

	memmap_entries := boot_info.memmap_entries
	last_physical_address: uintptr

	// The usable regions are sorted by base address and page-aligned.
	#reverse for entry, i in memmap_entries {
		if entry.type == limine.MEMMAP_USABLE {
			memmap_entries = memmap_entries[:i + 1]
			last_physical_address = uintptr(entry.base + entry.length)
			break
		}
	}

	pages: []Page
	pages_start, pages_end: u64

	{ 	// Find a suitable place for the pages array.
		best_entry: ^limine.memmap_entry
		pages_len := last_physical_address / PAGE_SIZE
		pages_size := u64(pages_len) * size_of(Page)

		// Find the largest
		for entry in memmap_entries {
			if entry.type == limine.MEMMAP_USABLE && entry.length >= pages_size {
				if best_entry == nil {
					best_entry = entry
				} else if entry.length > best_entry.length {
					best_entry = entry
				}
			}
		}

		if best_entry == nil {
			log_error("Failed to find a suitable region for the pages array")
			return
		}

		// Store the pages at the end of the largest region.
		pages_address := hhdm_base + uintptr(best_entry.base + best_entry.length - pages_size)
		pages = ([^]Page)(pages_address)[:pages_len]

		start_ptr := raw_data(pages)
		pages_start = u64(page_align_backward((uintptr(start_ptr) - hhdm_base)) / PAGE_SIZE)

		end_ptr := mem.ptr_offset(start_ptr, pages_len)
		pages_end = u64(page_align_forward((uintptr(end_ptr) - hhdm_base)) / PAGE_SIZE)
	}

	// Add the usable pages to the page allocator.
	page_allocator_init(&page_allocator, pages)

	for entry in memmap_entries {
		if entry.type != limine.MEMMAP_USABLE {
			continue
		}

		start := entry.base / PAGE_SIZE
		end := (entry.base + entry.length) / PAGE_SIZE

		// Skip the pages that are used to store the page metadata.
		if end == pages_end {
			end = pages_start
		}

		for start < end {
			// Compute the page order based on the start and end page numbers.
			start_align := Page_Order(bits.count_trailing_zeros(start))
			len_align := Page_Order(bits.log2(end - start))
			order := min(start_align, len_align, PAGE_ALLOCATOR_MAX_ORDER - 1)

			page_allocator_add_block(&page_allocator, &pages[start], order)
			start += 1 << order
		}
	}

	ok = true
	return
}

@(require_results)
page_alloc :: #force_inline proc "contextless" (order: Page_Order) -> (block: ^Page, ok: bool) {
	return page_allocator_alloc(&page_allocator, order)
}

page_free :: #force_inline proc "contextless" (block: ^Page) {
	page_allocator_free(&page_allocator, block)
}

@(require_results)
page_from_node :: #force_inline proc "contextless" (node: ^List_Node) -> ^Page {
	return container_of(node, Page, "node")
}

@(require_results)
page_align_forward :: #force_inline proc "contextless" (address: uintptr) -> uintptr {
	return (address + PAGE_MASK) & ~uintptr(PAGE_MASK)
}

@(require_results)
page_align_backward :: #force_inline proc "contextless" (address: uintptr) -> uintptr {
	return address & ~uintptr(PAGE_MASK)
}
