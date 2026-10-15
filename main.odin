package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:prof/spall"
import "core:sync"

spall_ctx: spall.Context
@(thread_local)
spall_buffer: spall.Buffer

main :: proc() {
	spall_ctx = spall.context_create("trace_test.spall")
	defer spall.context_destroy(&spall_ctx)

	buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
	defer delete(buffer_backing)

	spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
	defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

	spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	img, err := load_digit_png()
	if err != nil {
		fmt.eprint("Could not load the image.")
	}

	train()
	_ = make([]f64, 1_000)

	fmt.print("\n\n")
	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %m\n", leak.location, leak.size)
	}
	fmt.print("\n\n")
	fmt.print("Allocator tracking completed.\n")
}


train :: proc() {
	train_set: Dataset
	dataset_init(&train_set, 60_000, INPUT_SIZE, OUTPUT_SIZE, context.allocator)
	if !dataset_load_csv(&train_set, "mnist/mnist_train.csv") {
		fmt.eprint("Failed to load mnist_train.csv")
		return
	}
	defer dataset_destroy(&train_set)

	fmt.println("Training complete.")
}
