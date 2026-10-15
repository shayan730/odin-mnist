package main

import "core:testing"

@(test)
test_dataset_init_and_get :: proc(t: ^testing.T) {
	dataset: Dataset
	dataset_init(&dataset, 2, 3, 2)
	defer dataset_destroy(&dataset)

	copy(dataset.input, []f32{1, 2, 3, 4, 5, 6})
	copy(dataset.output, []f32{1, 0, 0, 1})

	input, output := dataset_get(&dataset, 1)

	testing.expect(t, len(input) == 3)
	testing.expect(t, len(output) == 2)
	testing.expect(t, input[0] == 4)
	testing.expect(t, input[1] == 5)
	testing.expect(t, input[2] == 6)
	testing.expect(t, output[0] == 0)
	testing.expect(t, output[1] == 1)
}


@(test)
test_dataset_sample_respects_order :: proc(t: ^testing.T) {
	dataset: Dataset
	dataset_init(&dataset, 3, 2, 1)
	defer dataset_destroy(&dataset)

	copy(dataset.input, []f32{10, 11, 20, 21, 30, 31})

	// Make the sampling order explicit so the test is deterministic.
	copy(dataset.order, []int{2, 0, 1})

	input, _ := dataset_sample(&dataset, 0)
	testing.expect(t, input[0] == 30)
	testing.expect(t, input[1] == 31)

	input, _ = dataset_sample(&dataset, 1)
	testing.expect(t, input[0] == 10)
	testing.expect(t, input[1] == 11)

	input, _ = dataset_sample(&dataset, 2)
	testing.expect(t, input[0] == 20)
	testing.expect(t, input[1] == 21)
}


@(test)
test_dataset_shuffle_preserves_indices :: proc(t: ^testing.T) {
	dataset: Dataset
	dataset_init(&dataset, 100, 1, 1)
	defer dataset_destroy(&dataset)

	dataset_shuffle(&dataset)

	seen := make([]bool, dataset.size)
	defer delete(seen)

	for index in dataset.order {
		testing.expect(t, index >= 0 && index < dataset.size)

		// A shuffle should produce a permutation, not duplicate/drop indices.
		testing.expect(t, !seen[index])
		seen[index] = true
	}

	for value in seen {
		testing.expect(t, value)
	}
}
