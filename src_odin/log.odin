package kernel

QEMU_DEBUG_PORT :: 0xe9

log_string :: proc "contextless" (message: string, eof := "\n") {
	for byte in transmute([]u8)message {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	for byte in transmute([]u8)eof {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}
}

log_int :: proc "contextless" (#any_int value: int, eof := "\n") {
	digits: [32]u8
	digits_len := 0
	rem := abs(value)

	for digits_len < len(digits) {
		digit := u8(rem % 10) + u8('0')
		digits[len(digits) - digits_len - 1] = digit
		digits_len += 1
		rem /= 10

		if rem == 0 {
			break
		}
	}

	if value < 0 && digits_len < len(digits) {
		digits[len(digits) - digits_len - 1] = '-'
		digits_len += 1
	}

	used_digits := digits[len(digits) - digits_len:len(digits)]
	log_string(string(used_digits), eof)
}

log_address :: proc "contextless" (address: u64, eof := "\n") {
	digits: [16]u8
	digits_len := 0
	rem := abs(address)

	for digits_len < len(digits) {
		digit := hex_char_from_digit(u8(rem % 16))
		digits[len(digits) - digits_len - 1] = digit
		digits_len += 1
		rem /= 16

		if rem == 0 {
			break
		}
	}

	for &digit in digits[:len(digits) - digits_len] {
		digit = '0'
	}

	log_string(string(digits[:]), eof)
}

@(require_results)
hex_char_from_digit :: proc "contextless" (digit: u8) -> u8 {
	if digit < 10 {
		return '0' + digit
	} else if digit < 16 {
		return 'a' + (digit - 10)
	} else {
		return 0
	}
}
