func sort(_ arr: inout [Int]) {
	let n = arr.count
	for c in 0..<(n - 1) {
		for d in 0..<(n - c - 1) {
			if arr[d] > arr[d + 1] {
				arr.swapAt(d, d + 1)
			}
		}
	}
}

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
sort(&items)
print(items)
