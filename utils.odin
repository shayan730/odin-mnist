package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:mem"
import "core:prof/spall"

load_digit_png :: proc() -> (res: [INPUT_SIZE]f32, err: image.Error) {
	spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

	digit_image := png.load_from_file("digit.png") or_return
	defer png.destroy(digit_image)
	if err != nil {
		fmt.eprint("Failed to load digit.png")
	}
	pixels := mem.slice_data_cast([]image.RGBA_Pixel, digit_image.pixels.buf[:])
	for i in 0 ..< INPUT_SIZE {
		p := pixels[i]
		average_rgb := (f32(p.r) + f32(p.g) + f32(p.b)) / (255.0 * 3)
		res[i] = average_rgb * f32(p.a) / 255.0
	}
	return
}
