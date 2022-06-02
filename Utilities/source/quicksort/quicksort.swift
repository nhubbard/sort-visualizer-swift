import Foundation

func partition(_ array: inout [Int], _ begin: Int, _ end: Int) -> Int {
	let pivot = array[end]
	var i = begin - 1
	for j in begin..<end {
		if array[j] <= pivot {
			i += 1
			array.swapAt(i, j)
		}
	}
	array.swapAt(i + 1, end)
	return i + 1
}

func quickSort(_ array: inout [Int], _ begin: Int, _ end: Int) {
	if begin < end {
		let partitionIndex = partition(&array, begin, end)
		quickSort(&array, begin, partitionIndex - 1)
		quickSort(&array, partitionIndex + 1, end)
	}
}

var items: [Int] = [1, 5, 2, 3, 7, 4, 8, 9]
quickSort(&items, 0, items.count - 1)
print(items)