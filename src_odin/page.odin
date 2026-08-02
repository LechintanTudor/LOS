package kernel

import "core:log"
import "core:math/bits"
import "core:mem"
import "extern:limine"

PAGE_SIZE :: 4096
PAGE_MASK :: PAGE_SIZE - 1
PAGE_ALLOCATOR_MAX_ORDER :: 11

hhdm_offset: uintptr
pages: []Page
page_allocator: Page_Allocator

Page_Allocator :: struct {
	free_blocks: [PAGE_ALLOCATOR_MAX_ORDER]^Page,
}

Page :: struct {
	next_free_block: ^Page,
	prev_free_block: ^Page,
	flags:           Page_Flags,
}

Page_Number :: distinct uint

Page_Flags :: bit_set[Page_Flags_Bits;u32]

Page_Flags_Bits :: enum u32 {
	Used,
}

@(require_results)
page_init :: proc() -> (ok: bool) {
	hhdm_offset = boot_get_hhdm_offset()

	memmap_entries := boot_get_memmap_entries()
	last_physical_address: uintptr

	// The usable regions are sorted by base address and page-aligned.
	#reverse for entry, i in memmap_entries {
		if entry.type == limine.MEMMAP_USABLE {
			memmap_entries = memmap_entries[:i + 1]
			last_physical_address = uintptr(entry.base + entry.length)
			break
		}
	}

	pages_start, pages_end: Page_Number

	{ 	// Find a suitable place for the pages array.
		best_entry: ^limine.memmap_entry
		pages_len := Page_Number(last_physical_address / PAGE_SIZE)
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
			log.error("Failed to find a suitable region for the pages array")
			return
		}

		// Store the pages at the end of the largest region.
		pages_address := hhdm_offset + uintptr(best_entry.base + best_entry.length - pages_size)
		pages = ([^]Page)(pages_address)[:pages_len]

		start_ptr := raw_data(pages)
		pages_start = Page_Number(
			page_align_backward((uintptr(start_ptr) - hhdm_offset)) / PAGE_SIZE,
		)

		end_ptr := mem.ptr_offset(start_ptr, pages_len)
		pages_end = Page_Number(page_align_forward((uintptr(end_ptr) - hhdm_offset)) / PAGE_SIZE)
	}

	free_block_count := 0

	// Add the usable pages to the page allocator.
	for entry in memmap_entries {
		if entry.type != limine.MEMMAP_USABLE {
			continue
		}

		start := Page_Number(entry.base / PAGE_SIZE)
		end := Page_Number((entry.base + entry.length) / PAGE_SIZE)

		// Skip the pages that are used to store the page metadata.
		if end == pages_end {
			end = pages_start
		}

		for start < end {
			order := page_range_get_order(start, end)
			count := Page_Number(1) << order

			log.infof("%v..%v, order %v", start, end, order)

			free_block_count += 1
			start += count
		}
	}

	log.infof("Free block count: %v", free_block_count)
	log.infof("Page array pages: %v..%v", pages_start, pages_end)

	ok = true
	return
}

@(require_results)
page_align_forward :: #force_inline proc "contextless" (address: uintptr) -> uintptr {
	return (address + PAGE_MASK) & ~uintptr(PAGE_MASK)
}

@(require_results)
page_align_backward :: #force_inline proc "contextless" (address: uintptr) -> uintptr {
	return address & ~uintptr(PAGE_MASK)
}

@(require_results)
page_range_get_order :: proc "contextless" (start, end: Page_Number) -> uint {
	if end <= start {
		return 0
	}

	start_align := bits.count_trailing_zeros(start)
	len_align := bits.log2(end - start)
	return uint(min(start_align, len_align, PAGE_ALLOCATOR_MAX_ORDER - 1))
}
