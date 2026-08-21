package kernel

import "base:intrinsics"

Fmt :: struct {
	buf: []byte,
	len: int,
}

@(require_results)
fmt_create :: proc "contextless" (buf: []byte) -> Fmt {
	return {buf = buf}
}

fmt_clear :: proc "contextless" (fmt: ^Fmt) {
	fmt.len = 0
}

@(require_results)
fmt_get :: proc "contextless" (fmt: Fmt) -> string {
	return string(fmt.buf[:fmt.len])
}

fmt_write :: proc {
	fmt_write_string,
	fmt_write_int,
	fmt_write_address,
}

fmt_write_string :: proc "contextless" (fmt: ^Fmt, str: string) -> (ok: bool) {
	if _fmt_remaining_len(fmt^) < len(str) {
		return false
	}

	copy(fmt.buf[fmt.len:][:len(str)], str)
	fmt.len += len(str)
	return true
}

fmt_write_int :: proc "contextless" (fmt: ^Fmt, #any_int n: int) -> (ok: bool) {
	// Save the original length in case we need to revert.
	start_len := fmt.len

	if n < 0 {
		fmt_write(fmt, "-") or_return
	}

	// Use the formatter buffer as scrach space.
	buf := fmt.buf[fmt.len:]
	buf_len := 0

	n_rem := abs(n)

	// Write the digits in reverse order.
	for {
		// Ran out of scratch space. Revert the buffer and return.
		if buf_len >= len(buf) {
			fmt.len = start_len
			return false
		}

		buf[buf_len] = '0' + byte(n_rem % 10)

		n_rem /= 10
		buf_len += 1

		if n_rem <= 0 {
			break
		}
	}

	for i in 0 ..< (buf_len / 2) {
		_fmt_slice_swap(buf, i, buf_len - i - 1)
	}

	fmt.len += buf_len
	return true
}

fmt_write_address :: proc "contextless" (fmt: ^Fmt, address: VM_Virtual_Address) -> (ok: bool) {
	if _fmt_remaining_len(fmt^) < 16 {
		return false
	}

	buf := fmt.buf[fmt.len:][:16]
	buf_len := 16

	address_rem := address

	for {
		digit := address_rem % 16
		digit_char: byte

		if digit < 10 {
			digit_char = '0' + byte(digit)
		} else {
			digit_char = 'a' + byte(digit - 10)
		}

		buf[buf_len - 1] = digit_char

		address_rem /= 16
		buf_len -= 1

		if address_rem == 0 {
			break
		}
	}

	for &char in buf[:buf_len] {
		char = '0'
	}

	fmt.len += 16
	return true
}

@(require_results)
_fmt_remaining_len :: #force_inline proc "contextless" (fmt: Fmt) -> int {
	return len(fmt.buf) - fmt.len
}

_fmt_slice_swap :: #force_inline proc "contextless" (buf: []byte, a, b: int) {
	buf[a], buf[b] = buf[b], buf[a]
}
