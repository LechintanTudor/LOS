package kernel

Fmt :: struct {
	buf: []byte,
	len: int,
}

@(require_results)
fmt_create :: proc "contextless" (buf: []byte) -> Fmt {
	return {buf = buf}
}

@(require_results)
fmt_get :: proc "contextless" (fmt: Fmt) -> string {
	return string(fmt.buf[:fmt.len])
}

fmt_char :: proc "contextless" (fmt: ^Fmt, char: byte) -> (ok: bool) {
	if _fmt_remaining_len(fmt^) < 1 {
		return false
	}

	fmt.buf[fmt.len] = char
	fmt.len += 1
	return true
}

fmt_string :: proc "contextless" (fmt: ^Fmt, str: string) -> (ok: bool) {
	if _fmt_remaining_len(fmt^) < len(str) {
		return false
	}

	copy(fmt.buf[fmt.len:][:len(str)], str)
	fmt.len += len(str)
	return true
}


fmt_int :: proc "contextless" (fmt: ^Fmt, #any_int n: int) -> (ok: bool) {
	// Save the original length in case we need to revert.
	start_len := fmt.len

	if n < 0 {
		fmt_char(fmt, '-') or_return
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

@(require_results)
_fmt_remaining_len :: #force_inline proc "contextless" (fmt: Fmt) -> int {
	return len(fmt.buf) - fmt.len
}

_fmt_slice_swap :: #force_inline proc "contextless" (buf: []byte, a, b: int) {
	buf[a], buf[b] = buf[b], buf[a]
}
