package kernel

import "base:intrinsics"

@(export)
kernel_main :: proc "contextless" () {
	cpu_enable_sse()
	memory_init_from_limine()

	framebuffer := intrinsics.volatile_load(boot_framebuffer_request.response.framebuffers[0])
	pixels := ([^]u32)(framebuffer.address)

	for y in 0 ..< framebuffer.height {
		for x in 0 ..< framebuffer.width {
			i := y * (framebuffer.pitch / 4) + x
			nx := x * 255 / framebuffer.width
			ny := y * 255 / framebuffer.height
			intrinsics.volatile_store(&pixels[i], u32((ny << 8) | nx))
		}
	}

	cpu_halt_forever()
}
