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
	free: [PAGE_ALLOCATOR_MAX_ORDER]List_Head,
}

Page :: struct {
	node:  List_Node,
	order: Page_Order,
	flags: Page_Flags,
}

Page_Number :: distinct u64

Page_Order :: distinct u32

Page_Flags :: bit_set[Page_Flags_Bits;u32]

Page_Flags_Bits :: enum u32 {
	Used,
}

@(require_results)
memory_init :: proc() -> (ok: bool) {
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
	for &list in page_allocator.free {
		list_init(&list)
	}

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
			order := _page_order_from_range(start, end)
			_page_allocator_add_block(&pages[start], order)
			start += Page_Number(1) << order
		}
	}

	ok = true
	return
}

@(require_results)
page_allocator_alloc :: proc "contextless" (order: Page_Order) -> (block: ^Page, ok: bool) {
	// Try to get a suitable block by splitting a higher-order block.
	if list_is_empty(&page_allocator.free[order]) {
		return _page_allocator_split(order)
	}

	return _page_allocator_remove_block_of_order(order), true
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
_page_allocator_split :: proc "contextless" (order: Page_Order) -> (block: ^Page, ok: bool) {
	split_order: Page_Order

	// Search for the lowest higher-order block available.
	for i in order + 1 ..< len(page_allocator.free) {
		if !list_is_empty(&page_allocator.free[i]) {
			split_order = Page_Order(i)
			break
		}
	}

	if split_order == 0 {
		return nil, false
	}

	// Remove the higher-order block that needs to be split.
	block = _page_allocator_remove_block_of_order(split_order)

	for {
		target_order := split_order - 1

		// Add the buddy block to the target order free list.
		buddy := _page_get_buddy(block, target_order)
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
	list_push_back(&page_allocator.free[order], &block.node)
	block.order = order
	block.flags -= {.Used}
}

_page_allocator_remove_block :: proc "contextless" (block: ^Page) {
	list_remove(&block.node)
	block.flags += {.Used}
}

@(require_results)
_page_allocator_remove_block_of_order :: proc "contextless" (order: Page_Order) -> ^Page {
	block := _page_from_node(page_allocator.free[order].next)
	_page_allocator_remove_block(block)
	return block
}

@(require_results)
_page_from_node :: proc "contextless" (node: ^List_Node) -> ^Page {
	return container_of(node, Page, "node")
}

@(require_results)
_page_get_buddy :: proc "contextless" (block: ^Page, buddy_order: Page_Order) -> ^Page {
	block_number := _page_number_from_page(block)

	// (1 << buddy_order) is the bit that determines in which half of the parent
	// block of the higher order we are in. The line below flips that bit,
	// giving us the number of the buddy block of the correct order.
	buddy_number := block_number ~ (1 << buddy_order)

	return &pages[buddy_number]
}

@(require_results)
_page_number_from_page :: proc "contextless" (page: ^Page) -> Page_Number {
	return Page_Number((uintptr(page) - uintptr(&pages[0])) / size_of(Page))
}

@(require_results)
_page_order_from_range :: proc "contextless" (start, end: Page_Number) -> Page_Order {
	start_align := Page_Order(bits.count_trailing_zeros(start))
	len_align := Page_Order(bits.log2(end - start))
	return min(start_align, len_align, PAGE_ALLOCATOR_MAX_ORDER - 1)
}
