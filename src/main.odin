package kernel

import "base:intrinsics"
import "core:log"
import "core:mem"

@(export)
kernel_main :: proc "contextless" () {
	cpu_init()

	arena_buffer: [1024]byte
	arena: mem.Arena

	context = {}
	mem.arena_init(&arena, arena_buffer[:])

	context = {
		temp_allocator = mem.arena_allocator(&arena),
		logger         = logger_create(),
	}

	log.info("Booting...")

	boot_info, boot_ok := boot_init()

	if !boot_ok {
		cpu_halt_forever()
	}

	if !page_init(boot_info) {
		cpu_halt_forever()
	}

	framebuffer := boot_info.framebuffers[0]
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
