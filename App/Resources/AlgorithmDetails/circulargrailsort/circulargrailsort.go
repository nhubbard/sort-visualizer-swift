package main

import "fmt"

type circularGrail struct {
	items []int
	count int
}

func (s *circularGrail) swap(a, b int) {
	a %= s.count
	b %= s.count
	s.items[a], s.items[b] = s.items[b], s.items[a]
}

func (s *circularGrail) shiftForward(a, middle, end int) {
	for middle < end {
		s.swap(a, middle)
		a++
		middle++
	}
}

func (s *circularGrail) shiftBackward(start, middle, end int) {
	for middle > start {
		end--
		middle--
		s.swap(end, middle)
	}
}

func (s *circularGrail) insertion(start, end int) {
	for first := start + 1; first < end; first++ {
		for i := first; i > start && s.items[(i-1)%s.count] > s.items[i%s.count]; i-- {
			s.swap(i, i-1)
		}
	}
}

func (s *circularGrail) multiSwap(a, b, length int) {
	for i := 0; i < length; i++ {
		s.swap(a+i, b+i)
	}
}

func (s *circularGrail) rotate(start, middle, end int) {
	left, right := middle-start, end-middle
	for left > 0 && right > 0 {
		if right < left {
			s.multiSwap(middle-right, middle, right)
			end -= right
			middle -= right
			left -= right
		} else {
			s.multiSwap(start, middle, left)
			start += left
			middle += left
			right -= left
		}
	}
}

func (s *circularGrail) inPlaceMerge(start, middle, end int) {
	for i := start; i < middle && middle < end; {
		if s.items[i%s.count] > s.items[middle%s.count] {
			k := middle + 1
			for k < end && s.items[i%s.count] > s.items[k%s.count] {
				k++
			}
			s.rotate(i, middle, k)
			i += k - middle
			middle = k
		} else {
			i++
		}
	}
}

func (s *circularGrail) merge(p, start, middle, end int, full bool) int {
	i, j := start, middle
	for i < middle && j < end {
		if s.items[i%s.count] <= s.items[j%s.count] {
			s.swap(p, i)
			i++
		} else {
			s.swap(p, j)
			j++
		}
		p++
	}
	if i < middle {
		if i > p {
			s.shiftForward(p, i, middle)
		}
	} else if full {
		s.shiftForward(p, j, end)
	}
	if i < middle {
		return i
	}
	return j
}

func (s *circularGrail) blockLess(a, b, length int) bool {
	if s.items[a%s.count] != s.items[b%s.count] {
		return s.items[a%s.count] < s.items[b%s.count]
	}
	return s.items[(a+length-1)%s.count] < s.items[(b+length-1)%s.count]
}

func (s *circularGrail) blockMerge(start, middle, end, length int) {
	b1 := end - (end-middle-1)%length - 1
	if b1 <= middle {
		s.merge(start-length, start, middle, end, true)
		return
	}
	b2 := b1
	for i := middle - length; i > start && s.blockLess(b1, i, length); i -= length {
		b2 -= length
	}
	for j := start; j < b1-length; j += length {
		minimum := j
		for i := j + length; i < b1; i += length {
			if s.blockLess(i, minimum, length) {
				minimum = i
			}
		}
		if minimum != j {
			s.multiSwap(j, minimum, length)
		}
	}
	frontier := start
	for i := start + length; i < b2; i += length {
		frontier = s.merge(frontier-length, frontier, i, i+length, false)
		if frontier < i {
			s.shiftBackward(frontier, i, i+length)
			frontier += length
		}
	}
	s.merge(frontier-length, frontier, b1, end, true)
}

func sort(items []int) []int {
	s := circularGrail{items: items, count: len(items)}
	if s.count < 2 {
		return items
	}
	if s.count <= 16 {
		s.insertion(0, s.count)
		return items
	}
	block := 1
	for block*block < s.count {
		block *= 2
	}
	i, run, rolling, end := block, 1, s.count-block, s.count
	for run <= block {
		for i+2*run < end {
			s.merge(i-run, i, i+run, i+2*run, true)
			i += 2 * run
		}
		if i+run < end {
			s.merge(i-run, i, i+run, end, true)
		} else {
			s.shiftForward(i-run, i, end)
		}
		i = end + block - run
		end = i + rolling
		run *= 2
	}
	for run < rolling {
		for i+2*run < end {
			s.blockMerge(i, i+run, i+2*run, block)
			i += 2 * run
		}
		if i+run < end {
			s.blockMerge(i, i+run, end, block)
		} else {
			s.shiftForward(i-block, i, end)
		}
		i = end
		end += rolling
		run *= 2
	}
	s.insertion(i-block, i)
	s.inPlaceMerge(i-block, i, end)
	s.rotate(0, (i-block)%s.count, s.count)
	return items
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
