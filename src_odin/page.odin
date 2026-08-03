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
	order:           Page_Order,
	flags:           Page_Flags,
}

Page_Number :: distinct u64

Page_Order :: distinct u32

Page_Flags :: bit_set[Page_Flags_Bits;u32]

Page_Flags_Bits :: enum u32 {}

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
			order := page_order_from_range(start, end)
			_page_allocator_add_block(&pages[start], order)
			start += Page_Number(1) << order
		}
	}

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
page_order_from_range :: proc "contextless" (start, end: Page_Number) -> Page_Order {
	if end <= start {
		return 0
	}

	start_align := Page_Order(bits.count_trailing_zeros(start))
	len_align := Page_Order(bits.log2(end - start))
	return min(start_align, len_align, PAGE_ALLOCATOR_MAX_ORDER - 1)
}

@(require_results)
page_allocator_alloc :: proc "contextless" (order: Page_Order) -> (block: ^Page, ok: bool) {
	// Try to get a suitable block by splitting a higher-order block.
	if page_allocator.free_blocks[order] == nil {
		return _page_allocator_split(order)
	}

	return _page_allocator_remove_head_block(order), true
}

@(require_results)
_page_allocator_split :: proc "contextless" (order: Page_Order) -> (block: ^Page, ok: bool) {
	split_order: Page_Order

	// Search for the lowest higher-order block available.
	for i in order + 1 ..< len(page_allocator.free_blocks) {
		if page_allocator.free_blocks[i] != nil {
			split_order = Page_Order(i)
			break
		}
	}

	if split_order == 0 {
		return nil, false
	}

	// Remove the higher-order block that needs to be split.
	block = _page_allocator_remove_head_block(split_order)

	for {
		target_order := split_order - 1

		// Add the buddy block to the target order free list.
		buddy := _page_allocator_get_buddy(block, target_order)
		_page_allocator_add_block(buddy, target_order)

		// Exit when the block has the correct size.
		if target_order == order {
			break
		}

		split_order = target_order
	}

	block.order = order
	return block, true
}

_page_allocator_add_block :: proc "contextless" (block: ^Page, order: Page_Order) {
	head_block := &page_allocator.free_blocks[order]

	block.next_free_block = head_block^
	block.prev_free_block = nil
	block.order = order

	if head_block^ != nil {
		head_block^.prev_free_block = block
	}

	head_block^ = block
}

@(require_results)
_page_allocator_remove_head_block :: proc "contextless" (order: Page_Order) -> (block: ^Page) {
	block = page_allocator.free_blocks[order]
	next_block := block.next_free_block

	if next_block != nil {
		next_block.prev_free_block = nil
	}

	page_allocator.free_blocks[order] = next_block
	block.next_free_block = nil
	return block
}

@(require_results)
_page_allocator_get_buddy :: #force_inline proc "contextless" (
	block: ^Page,
	buddy_order: Page_Order,
) -> (
	buddy: ^Page,
) {
	return &([^]Page)(block)[1 << buddy_order]
}
