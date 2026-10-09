package main

import "fmt"

// The first fifth is the only external buffer; the other four merge through
// its vacated positions before a central backward merge restores the prefix.
type fifth struct {
	a, buffer []int
}

func (s *fifth) binaryInsertion(first, end int) {
	for i := first + 1; i < end; i++ {
		value, low, high := s.a[i], first, i
		for low < high {
			middle := low + (high-low)/2
			if s.a[middle] > value {
				high = middle
			} else {
				low = middle + 1
			}
		}
		for j := i; j > low; j-- {
			s.a[j] = s.a[j-1]
		}
		s.a[low] = value
	}
}

func (s *fifth) source(index, offset int, fromBuffer bool) int {
	if fromBuffer {
		return s.buffer[index-offset]
	}
	return s.a[index]
}

func (s *fifth) merge(offset, first, middle, end int, fromBuffer bool) {
	left, right := first, middle
	destination := first - offset
	if fromBuffer {
		destination = first
	}
	write := func(value int) {
		if fromBuffer {
			s.a[destination] = value
		} else {
			s.buffer[destination] = value
		}
		destination++
	}
	for left < middle && right < end {
		if s.source(left, offset, fromBuffer) <= s.source(right, offset, fromBuffer) {
			write(s.source(left, offset, fromBuffer))
			left++
		} else {
			write(s.source(right, offset, fromBuffer))
			right++
		}
	}
	for left < middle {
		write(s.source(left, offset, fromBuffer))
		left++
	}
	for right < end {
		write(s.source(right, offset, fromBuffer))
		right++
	}
}

func (s *fifth) pingPong(first, end int) {
	i := first
	for i+8 < end {
		s.binaryInsertion(i, i+8)
		i += 8
	}
	if end-i > 1 {
		s.binaryInsertion(i, end)
	}
	length, fromBuffer := end-first, false
	for gap := 8; gap < length; gap *= 2 {
		full := gap * 2
		i = first
		for i+full < end {
			s.merge(first, i, i+gap, i+full, fromBuffer)
			i += full
		}
		if i+gap < end {
			s.merge(first, i, i+gap, end, fromBuffer)
		} else {
			for j := i; j < end; j++ {
				if fromBuffer {
					s.a[j] = s.buffer[j-first]
				} else {
					s.buffer[j-first] = s.a[j]
				}
			}
		}
		fromBuffer = !fromBuffer
	}
	if fromBuffer {
		for j := 0; j < length; j++ {
			s.a[first+j] = s.buffer[j]
		}
	}
}

func (s *fifth) mergeForward(destination, first, middle, end int) {
	left, right := first, middle
	for left < middle && right < end {
		if s.a[left] <= s.a[right] {
			s.a[destination] = s.a[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < middle {
		s.a[destination] = s.a[left]
		destination++
		left++
	}
	for right < end {
		s.a[destination] = s.a[right]
		destination++
		right++
	}
}

func (s *fifth) mergeBackward(destination, middle, end int) (int, int) {
	left, right := middle-1, end-1
	for destination > right && right >= middle && left >= 0 {
		if s.a[left] > s.a[right] {
			s.a[destination] = s.a[left]
			left--
		} else {
			s.a[destination] = s.a[right]
			right--
		}
		destination--
	}
	if left < 0 {
		for right >= middle {
			s.a[destination] = s.a[right]
			destination--
			right--
		}
	} else if right == left {
		for right >= 0 {
			s.a[destination] = s.a[right]
			destination--
			right--
		}
	} else if right < middle {
		for left >= 0 {
			s.a[destination] = s.a[left]
			destination--
			left--
		}
	}
	return left + 1, right + 1
}

func (s *fifth) mergeMainPrefix(destination, leftEnd, middle, end int) {
	left, right := 0, middle
	for left < leftEnd && right < end {
		if s.a[left] <= s.a[right] {
			s.a[destination] = s.a[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < leftEnd {
		s.a[destination] = s.a[left]
		destination++
		left++
	}
}

func (s *fifth) mergeExternal(destination, middle, end int) {
	left, right := 0, middle
	for left < len(s.buffer) && right < end {
		if s.buffer[left] <= s.a[right] {
			s.a[destination] = s.buffer[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < len(s.buffer) {
		s.a[destination] = s.buffer[left]
		destination++
		left++
	}
}

func sort(a []int) {
	n := len(a)
	if n <= 1 {
		return
	}
	chunk := n / 5
	bufferLength := n - 4*chunk
	s := fifth{a: a, buffer: make([]int, bufferLength)}
	s.pingPong(0, bufferLength)
	first := bufferLength
	for i := 0; i < 4; i++ {
		s.pingPong(first, first+chunk)
		first += chunk
	}
	copy(s.buffer, a[:bufferLength])
	twoFifths := 2 * chunk
	first = bufferLength
	for i := 0; i < 2; i++ {
		s.mergeForward(first-bufferLength, first, first+chunk, first+twoFifths)
		first += twoFifths
	}
	left, right := s.mergeBackward(n-1, twoFifths, 2*twoFifths)
	if right > 0 {
		s.mergeMainPrefix(bufferLength, left, twoFifths, n)
	}
	s.mergeExternal(0, bufferLength, n)
}

func main() {
	a := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	sort(a)
	fmt.Print("[")
	for i, value := range a {
		if i > 0 {
			fmt.Print(", ")
		}
		fmt.Print(value)
	}
	fmt.Println("]")
}
