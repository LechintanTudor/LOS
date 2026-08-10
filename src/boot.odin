package kernel

import "base:intrinsics"
import "core:log"
import "extern:limine"

@(private = "file")
volatile_load :: intrinsics.volatile_load

Boot_Info :: struct {
	hhdm_base:      uintptr,
	memmap_entries: []^limine.memmap_entry,
	framebuffers:   []^limine.framebuffer,
}

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

@(require_results)
boot_init :: proc() -> (info: Boot_Info, ok: bool) {
	{ 	// Frambuffer
		response := volatile_load(&_boot_framebuffer_request.response)

		if response == nil {
			log.error("Failed to set up framebuffers")
			return {}, false
		}

		info.framebuffers = response.framebuffers[:response.framebuffer_count]
	}

	{ 	// HHDM
		response := volatile_load(&_boot_hhdm_request.response)

		if response == nil {
			log.error("Failed to set up hhdm")
			return {}, false

		}

		info.hhdm_base = uintptr(response.offset)
	}

	{ 	// Memmap
		response := volatile_load(&_boot_memmap_request.response)

		if response == nil {
			log.error("Failed to get memmap entries")
			return {}, false
		}

		info.memmap_entries = response.entries[:response.entry_count]
	}

	return info, true
}
