package main

import "fmt"

const gap = 14
const ratio = 4

type flan struct {
	a        []int
	position [gap + 2]int
	heap     [gap + 2]int
	random   uint64
}

func min(x, y int) int {
	if x < y {
		return x
	}
	return y
}
func max(x, y int) int {
	if x > y {
		return x
	}
	return y
}
func (s *flan) swap(i, j int) { s.a[i], s.a[j] = s.a[j], s.a[i] }
func (s *flan) choice(n int) int {
	s.random ^= s.random >> 12
	s.random ^= s.random << 25
	s.random ^= s.random >> 27
	return int((s.random * 0x2545f4914f6cdd1d) % uint64(n))
}
func (s *flan) median(a, m, b int) int {
	if s.a[m] > s.a[a] {
		if s.a[m] < s.a[b] {
			return m
		}
		if s.a[a] > s.a[b] {
			return a
		}
		return b
	}
	if s.a[m] > s.a[b] {
		return m
	}
	if s.a[a] < s.a[b] {
		return a
	}
	return b
}
func (s *flan) ninther(a, b int) int {
	d := (b - a) / 9
	return s.median(s.median(a, a+d, a+2*d), s.median(a+3*d, a+4*d, a+5*d), s.median(a+6*d, a+7*d, a+8*d))
}
func (s *flan) pivot(a, b int) int {
	d := (b - a) / 3
	return s.median(s.ninther(a, a+d), s.ninther(a+d, a+2*d), s.ninther(a+2*d, b))
}
func (s *flan) binarySearch(a, b, value int, backward bool) int {
	for a < b {
		m := a + (b-a)/2
		found := s.a[m] > value
		if backward {
			found = s.a[m] < value
		}
		if found {
			b = m
		} else {
			a = m + 1
		}
	}
	return a
}
func (s *flan) insert(value, start, end int) {
	for start > end {
		start--
		s.a[start+1] = s.a[start]
	}
	s.a[end] = value
}
func (s *flan) insertion(a, b int) {
	for i := a + 1; i < b; i++ {
		value := s.a[i]
		s.insert(value, i, s.binarySearch(a, i, value, false))
	}
}
func (s *flan) blockSearch(a, b, value int, right bool) int {
	for a < b {
		m := a + ((b-a)/(gap+1)/2)*(gap+1)
		found := s.a[m] >= value
		if right {
			found = s.a[m] > value
		}
		if found {
			b = m
		} else {
			a = m + gap + 1
		}
	}
	return a
}
func (s *flan) retrieve(i, p, pEnd, boundary int, backward bool) {
	j := i - 1
	k := pEnd - (gap + 1)
	for k > p+gap {
		m := s.binarySearch(k-gap, k, boundary, backward) - 1
		k -= gap + 1
		for m >= k {
			s.swap(j, m)
			j--
			m--
		}
	}
	m := s.binarySearch(p, p+gap, boundary, backward) - 1
	for m >= p {
		s.swap(j, m)
		j--
		m--
	}
}
func (s *flan) librarySort(a, b, p, boundary int, backward bool) {
	length := b - a
	if length < 32 {
		s.insertion(a, b)
		return
	}
	count := length
	for count >= 32 {
		count = (count-1)/ratio + 1
	}
	i, j := a+count, a+ratio*count
	pEnd := p + (count+1)*(gap+1) + gap
	s.insertion(a, i)
	for k := 0; k < count; k++ {
		s.swap(a+k, p+k*(gap+1)+gap)
	}
	for i < b {
		if i == j {
			s.retrieve(i, p, pEnd, boundary, backward)
			count = i - a
			pEnd = p + (count+1)*(gap+1) + gap
			j = a + (j-a)*ratio
			for k := 0; k < count; k++ {
				s.swap(a+k, p+k*(gap+1)+gap)
			}
		}
		value := s.a[i]
		block := s.blockSearch(p+gap, pEnd-(gap+1), value, false)
		if s.a[block] == value {
			end := s.blockSearch(block+gap+1, pEnd-(gap+1), value, true)
			block += s.choice((end-block)/(gap+1)) * (gap + 1)
		}
		loc := s.binarySearch(block-gap, block, boundary, backward)
		if loc == block {
			for {
				block += gap + 1
				if block >= pEnd || s.binarySearch(block-gap, block, boundary, backward) != block {
					break
				}
			}
			if block == pEnd {
				s.retrieve(i, p, pEnd, boundary, backward)
				count = i - a
				pEnd = p + (count+1)*(gap+1) + gap
				j = a + (j-a)*ratio
				for k := 0; k < count; k++ {
					s.swap(a+k, p+k*(gap+1)+gap)
				}
			} else {
				rotation := s.binarySearch(block-gap, block, boundary, backward)
				distance := block - max(rotation, block-gap/2)
				m, end := block-distance, block
				for m > loc-distance {
					m--
					end--
					s.swap(end, m)
				}
			}
		} else {
			displaced := s.a[loc]
			s.a[i] = displaced
			i++
			s.insert(value, loc, s.binarySearch(block-gap, loc, value, false))
		}
	}
	s.retrieve(b, p, pEnd, boundary, backward)
}
func (s *flan) less(x, y int) bool {
	left, right := s.a[s.position[x]], s.a[s.position[y]]
	return left < right || (left == right && x < y)
}
func (s *flan) sift(item, root, size int) {
	for 2*root+2 < size {
		left := 2*root + 1
		child := left
		if !s.less(s.heap[left], s.heap[left+1]) {
			child++
		}
		if !s.less(s.heap[child], item) {
			break
		}
		s.heap[root] = s.heap[child]
		root = child
	}
	left := 2*root + 1
	if left < size && s.less(s.heap[left], item) {
		s.heap[root] = s.heap[left]
		root = left
	}
	s.heap[root] = item
}
func (s *flan) merge(runLength, b, dest, count int) {
	if count < 2 {
		if count == 1 {
			for s.position[0] < b {
				s.swap(dest, s.position[0])
				dest++
				s.position[0]++
			}
		}
		return
	}
	start := s.position[0]
	for i := 0; i < count; i++ {
		s.heap[i] = i
	}
	for i := (count - 1) / 2; i >= 0; i-- {
		s.sift(s.heap[i], i, count)
	}
	size := count
	for size > 0 {
		run := s.heap[0]
		s.swap(dest, s.position[run])
		dest++
		s.position[run]++
		if s.position[run] == min(start+(run+1)*runLength, b) {
			size--
			s.sift(s.heap[size], 0, size)
		} else {
			s.sift(s.heap[0], 0, size)
		}
	}
}
func sort(a []int) []int {
	if len(a) < 2 {
		return a
	}
	s := flan{a: a, random: 0x9e3779b97f4a7c15}
	for _, value := range a {
		s.random = (s.random^uint64(int64(value)))*0xbf58476d1ce4e5b9 + 0x94d049bb133111eb
	}
	left, right := 0, len(a)
	for right-left >= 32 {
		pivot := a[s.pivot(left, right)]
		first, i, j, last := left, left-1, right, right
		for {
			i++
			for i < j {
				if a[i] == pivot {
					s.swap(first, i)
					first++
				} else if a[i] < pivot {
					break
				}
				i++
			}
			j--
			for j > i {
				if a[j] == pivot {
					last--
					s.swap(last, j)
				} else if a[j] > pivot {
					break
				}
				j--
			}
			if i < j {
				s.swap(i, j)
			} else {
				if first == right {
					return a
				}
				if j < i {
					j++
				}
				for first > left {
					i--
					first--
					s.swap(i, first)
				}
				for last < right {
					s.swap(j, last)
					j++
					last++
				}
				break
			}
		}
		leftSize, rightSize, count := i-left, right-j, 0
		if leftSize <= rightSize {
			move := right - leftSize
			leftSize = max((rightSize+1)/(gap+1), 16)
			for k := left; k < i; k += leftSize {
				s.librarySort(k, min(k+leftSize, i), j, pivot, true)
				s.position[count] = k
				count++
			}
			s.merge(leftSize, i, move, count)
			if j-i < move-j {
				for i < j {
					move--
					s.swap(i, move)
					i++
				}
				right = move
			} else {
				for move > j {
					move--
					s.swap(i, move)
					i++
				}
				right = i
			}
		} else {
			move := left + rightSize
			rightSize = max((leftSize+1)/(gap+1), 16)
			for k := j; k < right; k += rightSize {
				s.librarySort(k, min(k+rightSize, right), left, pivot, false)
				s.position[count] = k
				count++
			}
			s.merge(rightSize, right, left, count)
			if i-move < j-i {
				for move < i {
					j--
					s.swap(move, j)
					move++
				}
				left = j
			} else {
				for j > i {
					j--
					s.swap(move, j)
					move++
				}
				left = move
			}
		}
	}
	s.insertion(left, right)
	return a
}
func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
