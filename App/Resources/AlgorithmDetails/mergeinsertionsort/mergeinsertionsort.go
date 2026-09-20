package main

import "fmt"

func blockSwap(arr []int, a, b, size int) {
	for offset := 0; offset < size; offset++ {
		x, y := a-size+1+offset, b-size+1+offset
		arr[x], arr[y] = arr[y], arr[x]
	}
}
func blockInsert(arr []int, a, b, size int) {
	for a-size >= b {
		blockSwap(arr, a-size, a, size)
		a -= size
	}
}
func blockReversal(arr []int, a, b, size int) {
	b -= size
	for b > a {
		blockSwap(arr, a, b, size)
		a += size
		b -= size
	}
}
func blockSearch(arr []int, a, b, size, value int) int {
	for a < b {
		mid := a + (((b-a)/size)/2)*size
		if value < arr[mid] {
			b = mid
		} else {
			a = mid + size
		}
	}
	return a
}
func order(arr []int, a, b, size int) {
	i, j := a, a+size
	for j < b {
		blockInsert(arr, j, i, size)
		i += size
		j += 2 * size
	}
	mid := a + (((b-a)/size)/2)*size
	blockReversal(arr, mid, b, size)
}
func sort(arr []int) []int {
	length := len(arr)
	if length < 2 {
		return arr
	}
	k := 1
	for 2*k <= length {
		for i := 2*k - 1; i < length; i += 2 * k {
			if arr[i-k] > arr[i] {
				blockSwap(arr, i-k, i, k)
			}
		}
		k *= 2
	}
	for k > 0 {
		a, i, g, p := k-1, 3*k-1, 2, 4
		for i+2*k*g-k <= length {
			order(arr, i, i+2*k*g-k, k)
			b := a + k*(p-1)
			i += k*g - k
			for j := i; j < i+k*g; j += k {
				blockInsert(arr, j, blockSearch(arr, a, b, k, arr[j]), k)
			}
			i += k*g + k
			g = p - g
			p *= 2
		}
		for i < length {
			blockInsert(arr, i, blockSearch(arr, a, i, k, arr[i]), k)
			i += 2 * k
		}
		k /= 2
	}
	return arr
}

func main() {
	array := []int{34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60}
	fmt.Println(sort(array))
}
