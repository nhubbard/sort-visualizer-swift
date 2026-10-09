package main

import "fmt"

func reverse(arr []int, a, b int) {
	b--
	for a < b {
		arr[a], arr[b] = arr[b], arr[a]
		a++
		b--
	}
}

func rotate(arr []int, a, m, b int) {
	reverse(arr, a, m)
	reverse(arr, m, b)
	reverse(arr, a, b)
}

func search(arr []int, a, b, value int, upper bool) int {
	for a < b {
		mid := (a + b) / 2
		if value < arr[mid] || (!upper && value == arr[mid]) {
			b = mid
		} else {
			a = mid + 1
		}
	}
	return a
}

func gallop(arr []int, a, b, value int, backwards bool) int {
	step := 1
	if backwards {
		for b-step >= a && value < arr[b-step] {
			step *= 2
		}
		return search(arr, max(a, b-step+1), b-step/2, value, true)
	}
	for a-1+step < b && value > arr[a-1+step] {
		step *= 2
	}
	return search(arr, a+step/2, min(b, a-1+step), value, false)
}

func insertion(arr []int, a, b int) {
	for i := a + 1; i < b; i++ {
		value := arr[i]
		position := search(arr, a, i, value, true)
		for j := i; j > position; j-- {
			arr[j] = arr[j-1]
		}
		arr[position] = value
	}
}

func forward(arr []int, a, m, b int) {
	i, j := a, m
	for i < j && j < b {
		if arr[i] > arr[j] {
			k := gallop(arr, j+1, b, arr[i], false)
			rotate(arr, i, j, k)
			i += k - j
			j = k
		} else {
			i++
		}
	}
}

func backward(arr []int, a, m, b int) {
	i, j := m-1, b-1
	for j > i && i >= a {
		if arr[i] > arr[j] {
			k := gallop(arr, a, i, arr[j], true)
			rotate(arr, k, i+1, j+1)
			j -= i + 1 - k
			i = k - 1
		} else {
			j--
		}
	}
}

func merge(arr []int, a, m, b int) {
	if b-m < m-a {
		backward(arr, a, m, b)
	} else {
		forward(arr, a, m, b)
	}
}

func fragmented(arr []int, a, m, b, size int) {
	i := a + (m-a)%size
	for i < m {
		j := gallop(arr, m, b, arr[i], false)
		rotate(arr, i, m, j)
		length, boundary := j-m, i
		i += length
		m += length
		merge(arr, a, boundary, i)
		a = i
		i += size
	}
	merge(arr, max(a, i-size), i, b)
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 16 {
		insertion(arr, 0, n)
		return arr
	}
	size := 1
	for size*size*size < n {
		size++
	}
	group := size * size
	for i := n % size; i <= n; i += size {
		insertion(arr, max(0, i-size), i)
	}
	i, j := n-size, n
	for i > 0 {
		if j-i == group {
			j -= group
			i -= size
		}
		forward(arr, max(0, i-size), i, j)
		i -= size
	}
	for i = n - group; i > 0; i -= group {
		fragmented(arr, max(0, i-group), i, n, size)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56,
		10, 2, 95, 46, 21, 74, 6, 38}
	fmt.Println(sort(array))
}
