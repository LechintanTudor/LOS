package kernel

intr_init :: proc "contextless" () {
	intr_amd64_init()
}
