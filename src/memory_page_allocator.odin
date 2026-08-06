package kernel

PAGE_ALLOCATOR_MAX_ORDER :: 11

Page_Allocator :: struct {
	pages: []Page,
	free:  [PAGE_ALLOCATOR_MAX_ORDER]List_Head,
}

page_allocator_init :: proc "contextless" (allocator: ^Page_Allocator, pages: []Page) {
	allocator.pages = pages

	for &head in allocator.free {
		list_init(&head)
	}
}

page_allocator_add_block :: proc "contextless" (
	allocator: ^Page_Allocator,
	block: ^Page,
	order: Page_Order,
) {
	block.order = order
	block.flags += {.Free_Head}
	list_push_back(&allocator.free[order], &block.node)
}

@(require_results)
page_allocator_alloc :: proc "contextless" (
	allocator: ^Page_Allocator,
	order: Page_Order,
) -> (
	block: ^Page,
	ok: bool,
) {
	// Try to get a suitable block by splitting a higher-order block.
	if list_is_empty(&allocator.free[order]) {
		return _page_allocator_split(allocator, order)
	}

	return _page_allocator_remove_block_of_order(allocator, order), true
}

page_allocator_free :: proc "contextless" (allocator: ^Page_Allocator, block: ^Page) {
	block := block
	order := block.order

	for {
		buddy := _page_allocator_get_page_buddy(allocator, block, order)

		if .Free_Head not_in buddy.flags || buddy.order != order {
			break
		}

		_page_allocator_remove_block(allocator, buddy)

		if uintptr(buddy) < uintptr(block) {
			block = buddy
		}

		order += 1

		if order == PAGE_ALLOCATOR_MAX_ORDER {
			break
		}
	}

	page_allocator_add_block(allocator, block, order)
}

_page_allocator_split :: proc "contextless" (
	allocator: ^Page_Allocator,
	order: Page_Order,
) -> (
	block: ^Page,
	ok: bool,
) {
	split_order := Page_Order(0)

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
	block = _page_allocator_remove_block_of_order(allocator, split_order)

	for {
		target_order := split_order - 1

		// Add the buddy block to the target order free list.
		buddy := _page_allocator_get_page_buddy(allocator, block, target_order)
		page_allocator_add_block(allocator, buddy, order)

		// Exit when the block has the correct size.
		if target_order == order {
			break
		}

		split_order = target_order
	}

	block.order = order
	return block, true
}

_page_allocator_remove_block_of_order :: proc "contextless" (
	allocator: ^Page_Allocator,
	order: Page_Order,
) -> ^Page {
	block := page_from_node(allocator.free[order].next)
	list_remove(&block.node)
	return block
}

_page_allocator_remove_block :: proc "contextless" (allocator: ^Page_Allocator, block: ^Page) {
	list_remove(&block.node)
	block.flags -= {.Free_Head}
}

@(require_results)
_page_allocator_get_page_buddy :: proc "contextless" (
	allocator: ^Page_Allocator,
	block: ^Page,
	buddy_order: Page_Order,
) -> ^Page {
	block_number := _page_allocator_get_page_number(allocator, block)

	// (1 << buddy_order) is the bit that determines in which half of the parent
	// block of the higher order we are in. The line below flips that bit,
	// giving us the number of the buddy block of the correct order.
	buddy_number := block_number ~ (1 << buddy_order)

	return &allocator.pages[buddy_number]
}

@(require_results)
_page_allocator_get_page_number :: #force_inline proc "contextless" (
	allocator: ^Page_Allocator,
	page: ^Page,
) -> int {
	return int((uintptr(page) - uintptr(&allocator.pages[0])) / size_of(Page))
}
