package kernel

import "extern:limine"

@(require, link_section = ".limine_requests_start")
boot_requests_start_marker := limine.REQUESTS_START_MARKER

@(require, link_section = ".limine_requests_end")
boot_requests_end_marker := limine.REQUESTS_END_MARKER

@(require, link_section = ".limine_requests")
boot_framebuffer_request := limine.framebuffer_request {
	id = limine.FRAMEBUFFER_REQUEST_ID,
}
