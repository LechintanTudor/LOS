package kernel

import "base:intrinsics"
import "core:log"
import "extern:limine"

@(private = "file")
volatile_load :: intrinsics.volatile_load

@(require, link_section = ".limine_requests_start")
_boot_requests_start_marker := limine.REQUESTS_START_MARKER

@(require, link_section = ".limine_requests_end")
_boot_requests_end_marker := limine.REQUESTS_END_MARKER

@(require, link_section = ".limine_requests")
_boot_base_revision := limine.LAST_BASE_REVISION

@(link_section = ".limine_requests")
_boot_framebuffer_request := limine.framebuffer_request {
	id = limine.FRAMEBUFFER_REQUEST_ID,
}

@(link_section = ".limine_requests")
_boot_hhdm_request := limine.hhdm_request {
	id = limine.HHDM_REQUEST_ID,
}

@(link_section = ".limine_requests")
_boot_memmap_request := limine.memmap_request {
	id = limine.MEMMAP_REQUEST_ID,
}

boot_validate :: proc() -> (ok: bool) {
	if volatile_load(&_boot_framebuffer_request.response) == nil {
		log.error("Failed to set up framebuffer")
		return
	}

	if volatile_load(&_boot_hhdm_request.response) == nil {
		log.error("Failed to set up hhdm")
		return
	}

	if volatile_load(&_boot_memmap_request.response) == nil {
		log.error("Failed to query memmap")
		return
	}

	ok = true
	return
}

@(require_results)
boot_get_framebuffers :: proc "contextless" () -> []^limine.framebuffer {
	response := volatile_load(&_boot_framebuffer_request.response)
	return response.framebuffers[:response.framebuffer_count]
}

@(require_results)
boot_get_hhdm_offset :: proc "contextless" () -> uintptr {
	response := volatile_load(&_boot_hhdm_request.response)
	return uintptr(response.offset)
}

// From Limine's protocol specification:
// - The entries are guaranteed to be sorted by base address, lowest to highest.
// - Usable entries are guaranteed to be 4096 byte aligned for both base and length.
@(require_results)
boot_get_memmap_entries :: proc "contextless" () -> []^limine.memmap_entry {
	response := volatile_load(&_boot_memmap_request.response)
	return response.entries[:response.entry_count]
}
