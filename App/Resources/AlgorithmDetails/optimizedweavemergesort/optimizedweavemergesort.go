package main

import (
	"fmt"
)

func insertTo(arr []int, a, b int) {
	temp := arr[a]
	for a > b {
		a--
		arr[a+1] = arr[a]
	}
	arr[b] = temp
}

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func rotate(arr []int, a, m, b int) {
	l := m - a
	r := b - m
	for l > 0 && r > 0 {
		if r < l {
			multiSwap(arr, m-r, m, r)
			b -= r
			m -= r
			l -= r
		} else {
			multiSwap(arr, a, m, l)
			a += l
			m += l
			r -= l
		}
	}
}

func bitReversal(arr []int, a, b int) {
	length := b - a
	m := 0
	d1 := length >> 1
	d2 := d1 + (d1 >> 1)
	i := 1
	for i < length-1 {
		j := d1
		k := i
		nn := d2
		for k&1 == 0 {
			j -= nn
			k >>= 1
			nn >>= 1
		}
		m += j
		if m > i {
			arr[a+i], arr[a+m] = arr[a+m], arr[a+i]
		}
		i++
	}
}

func weaveInsert(arr []int, a, b int, rightInit bool) {
	right := rightInit
	i := a
	j := a + 1
	for j < b {
		if right {
			for i < j && arr[i] <= arr[j] {
				i++
			}
		} else {
			for i < j && arr[i] < arr[j] {
				i++
			}
		}
		if i == j {
			right = !right
			j++
		} else {
			insertTo(arr, j, i)
			i++
			j += 2
		}
	}
}

func weaveMerge(arr []int, a, mInit, b int) {
	if b-a < 2 {
		return
	}
	a1 := a
	b1 := b
	right := true
	if (b-a)%2 == 1 {
		if mInit-a < b-mInit {
			a1 -= 1
			right = false
		} else {
			b1 += 1
		}
	}
	e := b1
	for e-a1 > 2 {
		m := (a1 + e) / 2
		p := 1
		for p*2 <= m-a1 {
			p *= 2
		}
		rotate(arr, m-p, m, e-p)
		m = e - p
		f := m - p
		bitReversal(arr, f, m)
		bitReversal(arr, m, e)
		bitReversal(arr, f, e)
		e = f
	}
	weaveInsert(arr, a, b, right)
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	d := 1
	for d < n {
		d <<= 1
	}
	for d > 1 {
		i := 0
		dec := 0
		for i < n {
			j := i
			dec += n
			for dec >= d {
				dec -= d
				j++
			}
			k := j
			dec += n
			for dec >= d {
				dec -= d
				k++
			}
			weaveMerge(arr, i, j, k)
			i = k
		}
		d /= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
