func selectionSort(_ arr: inout [Int]) {
	let n = arr.count
	for i in 0..<(n - 1) {
		var minIdx = i
		for j in (i + 1)..<n {
			if arr[j] < arr[minIdx] {
				minIdx = j
			}
		}
		arr.swapAt(minIdx, i)
	}
}

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
selectionSort(&items)
print(items)
