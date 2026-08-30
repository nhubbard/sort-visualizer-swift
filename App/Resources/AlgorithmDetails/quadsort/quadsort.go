package main

import (
	"fmt"
)

func swap2(arr []int, i int, j int) {
	arr[i], arr[j] = arr[j], arr[i]
}

func reverseInclusive(arr []int, lo int, hi int) {
	for lo < hi {
		swap2(arr, lo, hi)
		lo++
		hi--
	}
}

// -- Fixed-size sorting networks --------------------------------------------------------------

func swapTwo(arr []int, start int) {
	if arr[start] > arr[start+1] {
		swap2(arr, start, start+1)
	}
}

func swapThree(arr []int, start int) {
	if arr[start] > arr[start+1] {
		if arr[start] <= arr[start+2] {
			swap2(arr, start, start+1)
		} else if arr[start+1] > arr[start+2] {
			swap2(arr, start, start+2)
		} else {
			temp := arr[start]
			arr[start] = arr[start+1]
			arr[start+1] = arr[start+2]
			arr[start+2] = temp
		}
	} else if arr[start+1] > arr[start+2] {
		if arr[start] > arr[start+2] {
			temp := arr[start+2]
			arr[start+2] = arr[start+1]
			arr[start+1] = arr[start]
			arr[start] = temp
		} else {
			swap2(arr, start+2, start+1)
		}
	}
}

func swapFour(arr []int, start int) {
	if arr[start] > arr[start+1] {
		swap2(arr, start, start+1)
	}
	if arr[start+2] > arr[start+3] {
		swap2(arr, start+2, start+3)
	}
	if arr[start+1] > arr[start+2] {
		if arr[start] <= arr[start+2] {
			if arr[start+1] <= arr[start+3] {
				swap2(arr, start+1, start+2)
			} else {
				temp := arr[start+1]
				arr[start+1] = arr[start+2]
				arr[start+2] = arr[start+3]
				arr[start+3] = temp
			}
		} else if arr[start] > arr[start+3] {
			swap2(arr, start+1, start+3)
			swap2(arr, start, start+2)
		} else if arr[start+1] <= arr[start+3] {
			temp := arr[start+1]
			arr[start+1] = arr[start]
			arr[start] = arr[start+2]
			arr[start+2] = temp
		} else {
			temp := arr[start+1]
			arr[start+1] = arr[start]
			arr[start] = arr[start+2]
			arr[start+2] = arr[start+3]
			arr[start+3] = temp
		}
	}
}

// `end` is a pointer used as an out-parameter, matching the original's `inout Int`.
func swapFive(arr []int, start int, end *int) {
	*end = start + 4
	pta := *end
	*end += 1
	ptt := pta
	pta -= 1

	if arr[pta] > arr[ptt] {
		key := arr[ptt]
		arr[ptt] = arr[pta]
		ptt -= 1
		pta -= 1

		if pta > start && arr[pta-1] > key {
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
		}

		if pta >= start && arr[pta] > key {
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
		}

		arr[ptt] = key
	}
}

func tailSwapEight(arr []int, start int, end *int) {
	pta := *end
	*end += 1
	ptt := pta
	pta -= 1

	if arr[pta] > arr[ptt] {
		key := arr[ptt]
		arr[ptt] = arr[pta]
		ptt -= 1
		pta -= 1

		if arr[pta-2] > key {
			for i := 0; i < 3; i++ {
				arr[ptt] = arr[pta]
				ptt -= 1
				pta -= 1
			}
		}

		if pta > start && arr[pta-1] > key {
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
		}

		if pta >= start && arr[pta] > key {
			arr[ptt] = arr[pta]
			ptt -= 1
			pta -= 1
		}

		arr[ptt] = key
	}
}

func swapSix(arr []int, start int, end *int) {
	swapFive(arr, start, end)
	tailSwapEight(arr, start, end)
}

func swapSeven(arr []int, start int, end *int) {
	swapSix(arr, start, end)
	tailSwapEight(arr, start, end)
}

func swapEight(arr []int, start int, end *int) {
	swapSeven(arr, start, end)
	tailSwapEight(arr, start, end)
}

// ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
// swapFive/Six/Seven/Eight handle the first 5-8 elements by hand, then a binary-search insertion
// (the `for top > 1` loop) places everything past index 8.
func tailSwap(arr []int, start int, nmemb int) {
	end := 0
	switch nmemb {
	case 0, 1:
		return
	case 2:
		swapTwo(arr, start)
		return
	case 3:
		swapThree(arr, start)
		return
	case 4:
		swapFour(arr, start)
		return
	case 5:
		swapFour(arr, start)
		swapFive(arr, start, &end)
		return
	case 6:
		swapFour(arr, start)
		swapSix(arr, start, &end)
		return
	case 7:
		swapFour(arr, start)
		swapSeven(arr, start, &end)
		return
	case 8:
		swapFour(arr, start)
		swapEight(arr, start, &end)
		return
	}

	swapFour(arr, start)
	swapEight(arr, start, &end)
	end = start + 8
	offset := 8

	for offset < nmemb {
		top := offset
		offset += 1
		pta := end
		end += 1
		ptt := pta
		pta -= 1

		if arr[pta] <= arr[ptt] {
			continue
		}

		temp := arr[ptt]
		for top > 1 {
			mid := top / 2
			if arr[pta-mid] > temp {
				pta -= mid
			}
			top -= mid
		}

		i := ptt
		for i > pta {
			arr[i] = arr[i-1]
			i -= 1
		}
		arr[pta] = temp
	}
}

// -- Parity merges --------------------------------------------------------------------------

func parityMerge4(arr []int, start int, dest []int, auxOffset int) {
	auxP := auxOffset
	ptl := start
	ptr := start + 4

	for i := 0; i < 3; i++ {
		if arr[ptl] <= arr[ptr] {
			dest[auxP] = arr[ptl]
			ptl += 1
		} else {
			dest[auxP] = arr[ptr]
			ptr += 1
		}
		auxP += 1
	}
	if arr[ptl] <= arr[ptr] {
		dest[auxP] = arr[ptl]
	} else {
		dest[auxP] = arr[ptr]
	}

	ptl = start + 3
	ptr = start + 7
	auxP += 4

	for i := 0; i < 3; i++ {
		if arr[ptl] > arr[ptr] {
			dest[auxP] = arr[ptl]
			ptl -= 1
		} else {
			dest[auxP] = arr[ptr]
			ptr -= 1
		}
		auxP -= 1
	}
	if arr[ptl] > arr[ptr] {
		dest[auxP] = arr[ptl]
	} else {
		dest[auxP] = arr[ptr]
	}
}

func parityMerge8(arr []int, from []int, start int) {
	mainP := start
	ptl := 0
	ptr := 8

	for i := 0; i < 7; i++ {
		if from[ptl] <= from[ptr] {
			arr[mainP] = from[ptl]
			ptl += 1
		} else {
			arr[mainP] = from[ptr]
			ptr += 1
		}
		mainP += 1
	}
	if from[ptl] <= from[ptr] {
		arr[mainP] = from[ptl]
	} else {
		arr[mainP] = from[ptr]
	}

	ptl = 7
	ptr = 15
	mainP += 8

	for i := 0; i < 7; i++ {
		if from[ptl] > from[ptr] {
			arr[mainP] = from[ptl]
			ptl -= 1
		} else {
			arr[mainP] = from[ptr]
			ptr -= 1
		}
		mainP -= 1
	}
	if from[ptl] > from[ptr] {
		arr[mainP] = from[ptl]
	} else {
		arr[mainP] = from[ptr]
	}
}

func parityMerge16(arr []int, start int, aux []int) {
	if arr[start+3] <= arr[start+4] && arr[start+7] <= arr[start+8] && arr[start+11] <= arr[start+12] {
		return
	}

	parityMerge4(arr, start, aux, 0)
	parityMerge4(arr, start+8, aux, 8)
	parityMerge8(arr, aux, start)
}

// -- Bottom-up tail merge -----------------------------------------------------------------------

func partialBackwardMerge(arr []int, aux []int, start int, nmemb int, block int) {
	m := start + block
	e := start + nmemb - 1
	r := m
	m -= 1

	if arr[m] <= arr[r] {
		return
	}
	for arr[m] <= arr[e] {
		e -= 1
	}

	for i := r; i < r+(e-m); i++ {
		aux[i-r] = arr[i]
	}

	s := e - r
	arr[e] = arr[m]
	e -= 1
	m -= 1

	if arr[start] <= aux[0] {
		for {
			for arr[m] > aux[s] {
				arr[e] = arr[m]
				e -= 1
				m -= 1
			}
			arr[e] = aux[s]
			e -= 1
			s -= 1
			if s < 0 {
				break
			}
		}
	} else {
		for {
			for arr[m] <= aux[s] {
				arr[e] = aux[s]
				e -= 1
				s -= 1
			}
			arr[e] = arr[m]
			e -= 1
			m -= 1
			if m < start {
				break
			}
		}
		for {
			arr[e] = aux[s]
			e -= 1
			s -= 1
			if s < 0 {
				break
			}
		}
	}
}

func tailMerge(arr []int, aux []int, start int, nmemb int, blockIn int) {
	block := blockIn
	pte := start + nmemb

	for block < nmemb {
		pta := start
		for pta+block < pte {
			if pta+block*2 < pte {
				partialBackwardMerge(arr, aux, pta, block*2, block)
				pta += block * 2
				continue
			}
			partialBackwardMerge(arr, aux, pta, pte-pta, block)
			break
		}
		block *= 2
	}
}

// -- Quad merge -----------------------------------------------------------------------------

func forwardMergeRead(arr []int, aux []int, toAux bool, i int) int {
	if toAux {
		return arr[i]
	}
	return aux[i]
}

func forwardMergeWrite(arr []int, aux []int, toAux bool, i int, value int) {
	if toAux {
		aux[i] = value
	} else {
		arr[i] = value
	}
}

func forwardMerge(arr []int, aux []int, start int, auxStart int, block int, toAux bool) {
	var mergeP, l, r int
	if toAux {
		mergeP = auxStart
		l = start
		r = start + block
	} else {
		mergeP = start
		l = auxStart
		r = auxStart + block
	}
	m := r
	e := r + block

	if forwardMergeRead(arr, aux, toAux, r-1) <= forwardMergeRead(arr, aux, toAux, e-1) {
		for l < m {
			if forwardMergeRead(arr, aux, toAux, l) <= forwardMergeRead(arr, aux, toAux, r) {
				forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
				mergeP += 1
				l += 1
			} else {
				forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
				mergeP += 1
				r += 1
			}
		}
		for r < e {
			forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
			mergeP += 1
			r += 1
		}
	} else {
		for r < e {
			if forwardMergeRead(arr, aux, toAux, l) > forwardMergeRead(arr, aux, toAux, r) {
				forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
				mergeP += 1
				r += 1
			} else {
				forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
				mergeP += 1
				l += 1
			}
		}
		for l < m {
			forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
			mergeP += 1
			l += 1
		}
	}
}

func quadMergeBlock(arr []int, start int, aux []int, block int) {
	blockX2 := block * 2
	cMax := start + block

	if arr[cMax-1] <= arr[cMax] {
		cMax += blockX2

		if arr[cMax-1] <= arr[cMax] {
			cMax -= block

			if arr[cMax-1] <= arr[cMax] {
				return
			}

			pts := 0
			c := start
			for {
				aux[pts] = arr[c]
				c += 1
				pts += 1
				if c >= cMax {
					break
				}
			}

			cMax = c + blockX2
			for {
				aux[pts] = arr[c]
				c += 1
				pts += 1
				if c >= cMax {
					break
				}
			}

			forwardMerge(arr, aux, start, 0, blockX2, false)
			return
		}

		pts := 0
		c := start
		cMax = start + blockX2
		for {
			aux[pts] = arr[c]
			c += 1
			pts += 1
			if c >= cMax {
				break
			}
		}
	} else {
		forwardMerge(arr, aux, start, 0, block, true)
	}

	forwardMerge(arr, aux, start+blockX2, blockX2, block, true)
	forwardMerge(arr, aux, start, 0, blockX2, false)
}

func quadMerge(arr []int, aux []int, start int, nmemb int, blockIn int) {
	pte := start + nmemb
	block := blockIn * 4

	for block*2 <= nmemb {
		pta := start
		for {
			quadMergeBlock(arr, pta, aux, block/4)
			pta += block
			if pta+block > pte {
				break
			}
		}
		tailMerge(arr, aux, pta, pte-pta, block/4)
		block *= 4
	}
	tailMerge(arr, aux, start, nmemb, block/4)
}

// -- Pre-sort pass --------------------------------------------------------------------------

// Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
// detector for strictly-decreasing runs -- reversed in place rather than merged. If the *entire*
// range turns out strictly decreasing, one reversal finishes the sort outright (returns 1);
// otherwise this finishes with parity-merge passes over what's left (returns 0).
func quadSwap(arr []int, start int, nmemb int) int {
	swapBuf := make([]int, 16)
	pta := start
	count := nmemb / 4
	pts := 0

swapper:
	for count > 0 {
		count -= 1

	innerA:
		for {
			if arr[pta] > arr[pta+1] {
				if arr[pta+2] > arr[pta+3] {
					if arr[pta+1] > arr[pta+2] {
						pts = pta
						pta += 4
						break innerA
					}
					swap2(arr, pta+2, pta+3)
				}
				swap2(arr, pta, pta+1)
			} else if arr[pta+2] > arr[pta+3] {
				swap2(arr, pta+2, pta+3)
			}

			if arr[pta+1] > arr[pta+2] {
				if arr[pta] <= arr[pta+2] {
					if arr[pta+1] <= arr[pta+3] {
						swap2(arr, pta+1, pta+2)
					} else {
						temp := arr[pta+1]
						arr[pta+1] = arr[pta+2]
						arr[pta+2] = arr[pta+3]
						arr[pta+3] = temp
					}
				} else if arr[pta] > arr[pta+3] {
					swap2(arr, pta+1, pta+3)
					swap2(arr, pta, pta+2)
				} else if arr[pta+1] <= arr[pta+3] {
					temp := arr[pta+1]
					arr[pta+1] = arr[pta]
					arr[pta] = arr[pta+2]
					arr[pta+2] = temp
				} else {
					temp := arr[pta+1]
					arr[pta+1] = arr[pta]
					arr[pta] = arr[pta+2]
					arr[pta+2] = arr[pta+3]
					arr[pta+3] = temp
				}
			}
			pta += 4
			continue swapper
		}

	innerB:
		for {
			if count > 0 {
				count -= 1

				if arr[pta] > arr[pta+1] {
					if arr[pta+2] > arr[pta+3] {
						if arr[pta+1] > arr[pta+2] {
							if arr[pta-1] > arr[pta] {
								pta += 4
								continue innerB
							}
						}
						swap2(arr, pta+2, pta+3)
					}
					swap2(arr, pta, pta+1)
				} else if arr[pta+2] > arr[pta+3] {
					swap2(arr, pta+2, pta+3)
				}

				if arr[pta+1] > arr[pta+2] {
					if arr[pta] <= arr[pta+2] {
						if arr[pta+1] <= arr[pta+3] {
							swap2(arr, pta+1, pta+2)
						} else {
							temp := arr[pta+1]
							arr[pta+1] = arr[pta+2]
							arr[pta+2] = arr[pta+3]
							arr[pta+3] = temp
						}
					} else if arr[pta] > arr[pta+3] {
						swap2(arr, pta, pta+2)
						swap2(arr, pta+1, pta+3)
					} else if arr[pta+1] <= arr[pta+3] {
						temp := arr[pta]
						arr[pta] = arr[pta+2]
						arr[pta+2] = arr[pta+1]
						arr[pta+1] = temp
					} else {
						temp := arr[pta]
						arr[pta] = arr[pta+2]
						arr[pta+2] = arr[pta+3]
						arr[pta+3] = arr[pta+1]
						arr[pta+1] = temp
					}
				}

				reverseInclusive(arr, pts, pta-1)
				pta += 4
				continue swapper
			}

			if pts == start {
				remainder := nmemb % 4
				if remainder == 3 {
					if arr[pta+1] > arr[pta+2] {
						remainder = 2
					} else {
						remainder = -1
					}
				}
				if remainder == 2 {
					if arr[pta] > arr[pta+1] {
						remainder = 1
					} else {
						remainder = -1
					}
				}
				if remainder == 1 {
					if arr[pta-1] > arr[pta] {
						remainder = 0
					} else {
						remainder = -1
					}
				}
				if remainder == 0 {
					reverseInclusive(arr, pts, pts+nmemb-1)
					return 1
				}
			}

			reverseInclusive(arr, pts, pta-1)
			break swapper
		}
	}

	tailSwap(arr, pta, nmemb%4)

	pta = start
	count = nmemb / 16
	for count > 0 {
		count -= 1
		parityMerge16(arr, pta, swapBuf)
		pta += 16
	}

	if nmemb%16 > 4 {
		tailMerge(arr, swapBuf, pta, nmemb%16, 4)
	}

	return 0
}

// -- Entry point -----------------------------------------------------------------------------

// sort dispatches by size: under 16 is a plain tailSwap; under 256 pre-sorts via quadSwap then
// finishes with tailMerge; 256 and up finishes with the full quadMerge pass instead.
func sort(arr []int) []int {
	n := len(arr)
	if n < 16 {
		tailSwap(arr, 0, n)
	} else if n < 256 {
		if quadSwap(arr, 0, n) == 0 {
			buffer := make([]int, 128)
			tailMerge(arr, buffer, 0, n, 16)
		}
	} else {
		if quadSwap(arr, 0, n) == 0 {
			buffer := make([]int, n/2)
			quadMerge(arr, buffer, 0, n, 16)
		}
	}
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
		66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50,
	}
	fmt.Println(sort(array))
}
