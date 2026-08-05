package main

import (
	"fmt"
)

var leonardo = []int{
	1, 1, 3, 5, 9, 15, 25, 41, 67, 109,
	177, 287, 465, 753, 1219, 1973, 3193, 5167, 8361, 13529, 21891,
}

func trailingZeroCount(value int) int {
	mask := value &^ 1
	trail := 0
	for mask != 0 && mask&1 == 0 {
		mask >>= 1
		trail++
	}
	return trail
}

func sift(array []int, pshiftIn int, headIn int) {
	pshift := pshiftIn
	head := headIn
	val := array[head]
	for pshift > 1 {
		rt := head - 1
		lf := head - 1 - leonardo[pshift-2]
		if val >= array[lf] && val >= array[rt] {
			break
		}
		if array[lf] >= array[rt] {
			array[head] = array[lf]
			head = lf
			pshift -= 1
		} else {
			array[head] = array[rt]
			head = rt
			pshift -= 2
		}
	}
	array[head] = val
}

func trinkle(array []int, pIn int, pshiftIn int, headIn int, isTrustyIn bool) {
	p := pIn
	pshift := pshiftIn
	head := headIn
	isTrusty := isTrustyIn
	val := array[head]
	for p != 1 {
		stepson := head - leonardo[pshift]
		if array[stepson] <= val {
			break
		}
		if !isTrusty && pshift > 1 {
			rt := head - 1
			lf := head - 1 - leonardo[pshift-2]
			if array[rt] >= array[stepson] || array[lf] >= array[stepson] {
				break
			}
		}
		array[head] = array[stepson]
		head = stepson
		trail := trailingZeroCount(p)
		p >>= trail
		pshift += trail
		isTrusty = false
	}
	if !isTrusty {
		array[head] = val
		sift(array, pshift, head)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	head := 0
	p := 1
	pshift := 1
	hi := n - 1

	for head < hi {
		if p&3 == 3 {
			sift(arr, pshift, head)
			p >>= 2
			pshift += 2
		} else {
			if leonardo[pshift-1] >= hi-head {
				trinkle(arr, p, pshift, head, false)
			} else {
				sift(arr, pshift, head)
			}
			if pshift == 1 {
				p <<= 1
				pshift -= 1
			} else {
				p <<= (pshift - 1)
				pshift = 1
			}
		}
		p |= 1
		head += 1
	}

	trinkle(arr, p, pshift, head, false)
	for pshift != 1 || p != 1 {
		if pshift <= 1 {
			trail := trailingZeroCount(p)
			p >>= trail
			pshift += trail
		} else {
			p <<= 2
			p ^= 7
			pshift -= 2
			trinkle(arr, p>>1, pshift+1, head-leonardo[pshift]-1, true)
			trinkle(arr, p, pshift, head-1, true)
		}
		head -= 1
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
