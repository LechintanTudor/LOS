package kernel

import "base:intrinsics"
import "core:log"
import "extern:limine"

@(private = "file")
volatile_load :: intrinsics.volatile_load

@(private = "file", require, link_section = ".limine_requests_start")
boot_requests_start_marker := limine.REQUESTS_START_MARKER

@(private = "file", require, link_section = ".limine_requests_end")
boot_requests_end_marker := limine.REQUESTS_END_MARKER

@(private = "file", require, link_section = ".limine_requests")
boot_base_revision := limine.LAST_BASE_REVISION

@(private = "file", link_section = ".limine_requests")
boot_framebuffer_request := limine.framebuffer_request {
	id = limine.FRAMEBUFFER_REQUEST_ID,
}

@(private = "file", link_section = ".limine_requests")
boot_hhdm_request := limine.hhdm_request {
	id = limine.HHDM_REQUEST_ID,
}

@(private = "file", link_section = ".limine_requests")
boot_memmap_request := limine.memmap_request {
	id = limine.MEMMAP_REQUEST_ID,
}

boot_validate :: proc() -> (ok: bool) {
	if volatile_load(&boot_framebuffer_request.response) == nil {
		log.error("Failed to set up framebuffer")
		return
	}

	if volatile_load(&boot_hhdm_request.response) == nil {
		log.error("Failed to set up hhdm")
		return
	}

	if volatile_load(&boot_memmap_request.response) == nil {
		log.error("Failed to query memmap")
		return
	}

	ok = true
	return
}

@(require_results)
boot_get_framebuffers :: proc "contextless" () -> []^limine.framebuffer {
	response := volatile_load(&boot_framebuffer_request.response)
	return response.framebuffers[:response.framebuffer_count]
}

@(require_results)
boot_get_hhdm_offset :: proc "contextless" () -> uintptr {
	response := volatile_load(&boot_hhdm_request.response)
	return uintptr(response.offset)
}

// From Limine's protocol specification:
// - The entries are guaranteed to be sorted by base address, lowest to highest.
// - Usable entries are guaranteed to be 4096 byte aligned for both base and length.
@(require_results)
boot_get_memmap_entries :: proc "contextless" () -> []^limine.memmap_entry {
	response := volatile_load(&boot_memmap_request.response)
	return response.entries[:response.entry_count]
}
