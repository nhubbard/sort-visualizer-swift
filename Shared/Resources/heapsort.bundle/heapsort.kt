fun heapify(arr: Array<Int>, n: Int, i: Int) {
	var largest = i
	var l = 2 * i + 1
	var r = 2 * i + 2
	if (l < n && arr[l] > arr[largest]) {
		largest = l
	}
	if (r < n && arr[r] > arr[largest]) {
		largest = r
	}
	if (largest != i) {
		var temp = arr[i]
		arr[i] = arr[largest]
		arr[largest] = temp
		heapify(arr, n, largest)
	}
}

fun sort(arr: Array<Int>) {
	var n = arr.size
	for (i in (n / 2 - 1) downTo 0) {
		heapify(arr, n, i)
	}
	for (i in (n - 1) downTo 0) {
		var temp = arr[0]
		arr[0] = arr[i]
		arr[i] = temp
		heapify(arr, i, 0)
	}
}

fun main() {
	var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
	sort(items)
	println("[%s]".format(items.joinToString(", ")))
}
