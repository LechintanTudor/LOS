package kernel

import "base:intrinsics"

@(export)
kernel_main :: proc "contextless" () {
	cpu_init()

	log_info("Booting...")

	boot_info, boot_ok := boot_init()

	if !boot_ok {
		cpu_halt_and_catch_fire()
	}

	int_init()

	if !vm_init(boot_info) {
		cpu_halt_and_catch_fire()
	}

	cpu_send_interrupt_100()

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

	cpu_halt_and_catch_fire()
}

@(private = "file", require, link_name = "__truncdfsf2")
_unused_0 :: proc "sysv" () -> ! {
	cpu_halt_and_catch_fire()
}

@(private = "file", require, link_name = "__mulsf3")
_unused_1 :: proc "sysv" () -> ! {
	cpu_halt_and_catch_fire()
}

@(private = "file", require, link_name = "__gesf2")
_unused_2 :: proc "sysv" () -> ! {
	cpu_halt_and_catch_fire()
}
