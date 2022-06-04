import Foundation

func heapify(_ array: inout [Int], _ length: Int, _ i: Int) {
	var largest = i
	let left = i * 2 + 1
	let right = left + 1
	if left < length && array[left] >= array[largest] {
		largest = left
	}
	if right < length && array[right] >= array[largest] {
		largest = right
	}
	if largest != i {
		array.swapAt(i, largest)
		heapify(&array, length, largest)
	}
}

func heapSort(_ array: inout [Int]) {
	let length = array.count
	var i = length / 2 - 1
	var k = length - 1
	while i >= 0 {
		heapify(&array, length, i)
		i -= 1
	}
	while k >= 0 {
		array.swapAt(0, k)
		heapify(&array, k, 0)
		k -= 1
	}
}

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
heapSort(&items)
print(items)
