package main

import "fmt"

func sort(a []int) []int {
	n := len(a)
	if n < 2 {
		return a
	}
	lo, hi := 0, n
	if hi > 1291 {
		hi = 1291
	}
	for lo < hi {
		mid := (lo + hi) / 2
		if mid*mid*mid >= n {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	block := lo
	runLength := block * block
	runs := (n-1)/runLength + 1
	keyLength := runLength
	if runs < 2 {
		keyLength = n
	}
	keys := make([]int, keyLength)
	for i := range keys {
		keys[i] = i
	}
	greater := func(x, y, base int) bool { vx, vy := a[base+x], a[base+y]; return vx > vy || vx == vy && x > y }
	var siftTable func(int, int, int, int)
	siftTable = func(root, length, base, item int) {
		j := root
		for 2*j+1 < length {
			j = 2*j + 1
			if j+1 < length && greater(keys[j+1], keys[j], base) {
				j++
			}
		}
		for j > root && greater(item, keys[j], base) {
			j = (j - 1) / 2
		}
		for j > root {
			item, keys[j] = keys[j], item
			j = (j - 1) / 2
		}
		keys[root] = item
	}
	tableSort := func(start, end int) {
		length := end - start
		if length < 2 {
			return
		}
		for i := (length - 1) / 2; i >= 0; i-- {
			siftTable(i, length, start, keys[i])
		}
		for i := length - 1; i > 0; i-- {
			item := keys[i]
			keys[i] = keys[0]
			siftTable(0, i, start, item)
		}
		for i := 0; i < length; i++ {
			if keys[i] == i {
				continue
			}
			held := a[start+i]
			j, next := i, keys[i]
			for {
				a[start+j] = a[start+next]
				keys[j] = j
				j, next = next, keys[next]
				if next == i {
					break
				}
			}
			a[start+j] = held
			keys[j] = j
		}
	}
	if runs < 2 {
		tableSort(0, n)
		return a
	}
	buffer := make([]int, runLength)
	heap := make([]int, runs)
	pos := make([]int, runs)
	dest := make([]int, runs)
	for r := 0; r < runs; r++ {
		begin := r * runLength
		end := begin + runLength
		if end > n {
			end = n
		}
		tableSort(begin, end)
		heap[r] = r
		pos[r] = begin
		dest[r] = begin
	}
	less := func(x, y int) bool { vx, vy := a[pos[x]], a[pos[y]]; return vx < vy || vx == vy && x < y }
	var sift func(int, int, int)
	sift = func(item, root, size int) {
		for 2*root+2 < size {
			left := 2*root + 1
			child := left
			if !less(heap[left], heap[left+1]) {
				child++
			}
			if !less(heap[child], item) {
				break
			}
			heap[root] = heap[child]
			root = child
		}
		left := 2*root + 1
		if left < size && less(heap[left], item) {
			heap[root] = heap[left]
			root = left
		}
		heap[root] = item
	}
	for i := (runs - 1) / 2; i >= 0; i-- {
		sift(heap[i], i, runs)
	}
	size := runs
	advance := func(run int) {
		pos[run]++
		end := (run + 1) * runLength
		if end > n {
			end = n
		}
		if pos[run] == end {
			size--
			sift(heap[size], 0, size)
		} else {
			sift(heap[0], 0, size)
		}
	}
	for i := 0; i < runLength; i++ {
		run := heap[0]
		buffer[i] = a[pos[run]]
		advance(run)
	}
	t, count, cursor := 0, 0, 0
	for pos[cursor]-dest[cursor] < block {
		cursor++
	}
	for {
		run := heap[0]
		a[dest[cursor]] = a[pos[run]]
		dest[cursor]++
		advance(run)
		count++
		if count == block {
			if cursor > 0 {
				keys[t] = dest[cursor]/block - block - 1
			} else {
				keys[t] = -1
			}
			t++
			cursor = 0
			count = 0
			for pos[cursor]-dest[cursor] < block {
				cursor++
			}
		}
		if size == 0 {
			break
		}
	}
	end := n
	for count > 0 {
		count--
		dest[cursor]--
		end--
		a[end] = a[dest[cursor]]
	}
	pos[runs-1] = end
	keys[len(keys)-1] = -1
	t = 0
	for keys[t] != -1 {
		t++
	}
	source := 0
	for r := 1; r < runs && source < dest[0]; r++ {
		for dest[r] < pos[r] {
			keys[t] = dest[r]/block - block
			t++
			for keys[t] != -1 {
				t++
			}
			copy(a[dest[r]:dest[r]+block], a[source:source+block])
			dest[r] += block
			source += block
		}
	}
	copy(a[:runLength], buffer)
	blocks := (end - runLength) / block
	for i := 0; i < blocks; i++ {
		if keys[i] == i {
			continue
		}
		copy(buffer[:block], a[runLength+i*block:runLength+(i+1)*block])
		j, next := i, keys[i]
		for {
			copy(a[runLength+j*block:runLength+(j+1)*block], a[runLength+next*block:runLength+(next+1)*block])
			keys[j] = j
			j, next = next, keys[next]
			if next == i {
				break
			}
		}
		copy(a[runLength+j*block:runLength+(j+1)*block], buffer[:block])
		keys[j] = j
	}
	return a
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
