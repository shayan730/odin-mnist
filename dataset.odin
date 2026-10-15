package main

import "core:encoding/csv"
import "core:math/rand"
import "core:os"
import "core:strconv"

// Dataset
Dataset :: struct {
	size:        int,
	input_size:  int,
	output_size: int,
	input:       []f32,
	output:      []f32,
	order:       []int,
}

dataset_init :: proc(
	dataset: ^Dataset,
	size, input_size, output_size: int,
	allocator := context.allocator,
) {
	dataset.size = size
	dataset.input_size = input_size
	dataset.output_size = output_size
	dataset.input = make([]f32, size * input_size, allocator)
	dataset.output = make([]f32, size * output_size, allocator)
	dataset.order = make([]int, size, allocator)

	for i in 0 ..< len(dataset.order) {
		dataset.order[i] = i
	}
}

dataset_destroy :: proc(dataset: ^Dataset) {
	delete(dataset.input)
	delete(dataset.output)
	delete(dataset.order)
}

dataset_shuffle :: proc(dataset: ^Dataset) {
	rand.shuffle(dataset.order)
}

dataset_get :: proc(dataset: ^Dataset, i: int) -> (input, output: []f32) {
	input = dataset.input[i * dataset.input_size:][:dataset.input_size]
	output = dataset.output[i * dataset.output_size:][:dataset.output_size]
	return
}

dataset_select :: proc(dataset: ^Dataset, i: int) -> (input, output: []f32) {
	return dataset_get(dataset, i)
}

dataset_sample :: proc(dataset: ^Dataset, i: int) -> (input, output: []f32) {
	index := dataset.order[i]
	return dataset_get(dataset, index)
}

dataset_load_csv :: proc(
	dataset: ^Dataset,
	file_name: string,
	allocator := context.allocator,
) -> (
	ok: bool,
) {
	data, file_err := os.read_entire_file(file_name, allocator)
	if file_err != nil {
		return false
	}
	defer delete(data)

	csv_reader: csv.Reader
	csv.reader_init_with_string(&csv_reader, cast(string)data, allocator)
	csv_reader.reuse_record = true
	csv_reader.reuse_record_buffer = true
	defer csv.reader_destroy(&csv_reader)

	_, header_err := csv.read(&csv_reader)
	if header_err != nil {
		return false
	}

	for i in 0 ..< dataset.size {
		values_str, row_err := csv.read(&csv_reader)
		if row_err != nil {
			break
		}
		y_int, _ := strconv.parse_i64(values_str[0])
		dataset.output[i * dataset.output_size + int(y_int)] = 1

		for j in 0 ..< dataset.input_size {
			value_int, _ := strconv.parse_i64(values_str[j + 1])
			dataset.input[i * dataset.input_size + j] = f32(value_int) / 255.0
		}
	}

	ok = true
	return

}
