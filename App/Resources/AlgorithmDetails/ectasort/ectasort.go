// MIT License
// Copyright (c) 2020-2021 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
package main

import "fmt"

type ecta struct {
	a, buffer, tags     []int
	block, bufferLength int
}

func minRun(size int) int {
	for size >= 32 {
		size = (size + 1) / 2
	}
	return size
}
func (e *ecta) insertion(start, end int) {
	for index := start + 1; index < end; index++ {
		value, low, high := e.a[index], start, index
		for low < high {
			middle := low + (high-low)/2
			if e.a[middle] > value {
				high = middle
			} else {
				low = middle + 1
			}
		}
		for cursor := index; cursor > low; cursor-- {
			e.a[cursor] = e.a[cursor-1]
		}
		e.a[low] = value
	}
}
func (e *ecta) copyMain(source, destination, count int) {
	if count > 0 {
		copy(e.a[destination:destination+count], e.a[source:source+count])
	}
}
func (e *ecta) mergeTo(start, middle, end, destination int) {
	left, right, output := start, middle, destination
	for left < middle && right < end {
		if e.a[left] <= e.a[right] {
			e.a[output] = e.a[left]
			left++
		} else {
			e.a[output] = e.a[right]
			right++
		}
		output++
	}
	for left < middle {
		e.a[output] = e.a[left]
		left++
		output++
	}
	for right < end {
		e.a[output] = e.a[right]
		right++
		output++
	}
}
func (e *ecta) pingPong(start, m1, m2, m3, end, workspace int) {
	second := workspace + m2 - start
	e.mergeTo(start, m1, m2, workspace)
	e.mergeTo(m2, m3, end, second)
	e.mergeTo(workspace, second, workspace+end-start, start)
}
func (e *ecta) mergeBackward(start, middle, end, workspace int) {
	count := end - middle
	e.copyMain(middle, workspace, count)
	left, right, output := middle-1, workspace+count-1, end
	for left >= start && right >= workspace {
		output--
		if e.a[left] > e.a[right] {
			e.a[output] = e.a[left]
			left--
		} else {
			e.a[output] = e.a[right]
			right--
		}
	}
	for right >= workspace {
		output--
		e.a[output] = e.a[right]
		right--
	}
}
func (e *ecta) mergeFromBuffer(start, middle, end, count int) {
	index, right, output := 0, middle, start
	for index < count && right < end {
		if e.a[right] >= e.buffer[index] {
			e.a[output] = e.buffer[index]
			index++
		} else {
			e.a[output] = e.a[right]
			right++
		}
		output++
	}
	for index < count {
		e.a[output] = e.buffer[index]
		index++
		output++
	}
}
func (e *ecta) dualMergeBackward(start, first, middle, end, count int) {
	index, split := count-1, count-(end-middle)
	left, output := middle-1, end
	for index >= split && left >= first {
		output--
		if e.a[left] < e.buffer[index] {
			e.a[output] = e.buffer[index]
			index--
		} else {
			e.a[output] = e.a[left]
			left--
		}
	}
	if left < first {
		for index >= 0 {
			output--
			e.a[output] = e.buffer[index]
			index--
		}
	} else {
		e.mergeFromBuffer(start, first, output, split)
	}
}
func (e *ecta) mergeSort(start, end, workspace, initialRun, capacity int) int {
	run, index := initialRun, start
	for index+run <= end {
		e.insertion(index, index+run)
		index += run
	}
	e.insertion(index, end)
	for 4*run <= capacity {
		index = start
		for index+4*run <= end {
			e.pingPong(index, index+run, index+2*run, index+3*run, index+4*run, workspace)
			index += 4 * run
		}
		if index+3*run < end {
			e.pingPong(index, index+run, index+2*run, index+3*run, end, workspace)
		} else if index+2*run < end {
			e.pingPong(index, index+run, index+2*run, end, end, workspace)
		} else if index+run < end {
			e.mergeBackward(index, index+run, end, workspace)
		}
		run *= 4
	}
	for run <= capacity {
		index = start
		for index+2*run <= end {
			e.mergeBackward(index, index+run, index+2*run, workspace)
			index += 2 * run
		}
		if index+run < end {
			e.mergeBackward(index, index+run, end, workspace)
		}
		run *= 2
	}
	return run
}
func (e *ecta) blockCycle(start, count, workspace int, excludeLast, forward bool) {
	stride := e.block
	if !forward {
		stride = -stride
	}
	for index := 0; index < count; index++ {
		next := e.tags[index]
		if index == next {
			continue
		}
		e.copyMain(start+index*stride, workspace, e.block)
		current := index
		for {
			if !(excludeLast && current == count-1) {
				e.copyMain(start+next*stride, start+current*stride, e.block)
			}
			e.tags[current] = current
			current = next
			next = e.tags[next]
			if next == index {
				break
			}
		}
		e.copyMain(workspace, start+current*stride, e.block)
		e.tags[current] = current
	}
}
func (e *ecta) ectaForward(start, middle, end int) {
	block := e.block
	left, right, tag, tagCount, saved, other := start, middle, 0, 0, 2*block, 0
	savedPosition, otherPosition := start-2*block, middle
	for {
		choice := 0
		if saved < block {
			choice = 1
		}
		for offset := 0; offset < block; offset++ {
			destination := savedPosition + offset
			if choice != 0 {
				destination = otherPosition + offset
			}
			if left < middle && right < end {
				if e.a[left] <= e.a[right] {
					e.a[destination] = e.a[left]
					left++
					saved++
				} else {
					e.a[destination] = e.a[right]
					right++
					other++
				}
			} else if left < middle {
				e.a[destination] = e.a[left]
				left++
				saved++
			} else {
				e.a[destination] = e.a[right]
				right++
				other++
			}
		}
		if choice == 0 {
			savedPosition += block
			saved -= block
		} else {
			otherPosition += block
			other -= block
		}
		if choice == 0 {
			e.tags[tagCount] = tag
			tag++
		} else {
			e.tags[tagCount] = -1
		}
		tagCount++
		if !(left < middle || right < end) {
			break
		}
	}
	if saved > 0 {
		e.tags[tagCount] = tag
		tag++
	}
	for index := 2; index < tagCount; index++ {
		if e.tags[index] == -1 {
			e.tags[index] = tag
			tag++
		}
	}
	e.blockCycle(start-2*block, tag, end-block, saved > 0, true)
	_ = other
}
func (e *ecta) ectaBackward(start, middle, end int) {
	block := e.block
	right, left, tag, tagCount, saved, other := end-1, middle-1, 0, 0, 2*block, 0
	savedPosition, otherPosition := end+2*block, middle
	for {
		choice := 0
		if saved < block {
			choice = 1
		}
		for offset := 1; offset <= block; offset++ {
			destination := savedPosition - offset
			if choice != 0 {
				destination = otherPosition - offset
			}
			if right >= middle && left >= start {
				if e.a[right] >= e.a[left] {
					e.a[destination] = e.a[right]
					right--
					saved++
				} else {
					e.a[destination] = e.a[left]
					left--
					other++
				}
			} else if right >= middle {
				e.a[destination] = e.a[right]
				right--
				saved++
			} else {
				e.a[destination] = e.a[left]
				left--
				other++
			}
		}
		if choice == 0 {
			savedPosition -= block
			saved -= block
		} else {
			otherPosition -= block
			other -= block
		}
		if choice == 0 {
			e.tags[tagCount] = tag
			tag++
		} else {
			e.tags[tagCount] = -1
		}
		tagCount++
		if !(right >= middle || left >= start) {
			break
		}
	}
	if saved > 0 {
		e.tags[tagCount] = tag
		tag++
	}
	for index := 2; index < tagCount; index++ {
		if e.tags[index] == -1 {
			e.tags[index] = tag
			tag++
		}
	}
	e.blockCycle(end+block, tag, start, saved > 0, false)
	_ = other
}
func sort(a []int) {
	n := len(a)
	if n < 2 {
		return
	}
	e := ecta{a: a}
	if n <= 32 {
		e.insertion(0, n)
		return
	}
	if n < 256 {
		e.bufferLength = n / 2
	} else {
		e.block = minRun(n)
		for e.block*e.block < n/2 {
			e.block *= 2
		}
		e.bufferLength = 2*e.block + n%e.block
	}
	e.buffer = make([]int, e.bufferLength)
	if e.block > 0 {
		e.tags = make([]int, (n-e.bufferLength)/e.block+1)
	}
	if n < 256 {
		copy(e.buffer, a[e.bufferLength:2*e.bufferLength])
		e.mergeSort(0, e.bufferLength, e.bufferLength, minRun(n), e.bufferLength)
		copy(a[e.bufferLength:2*e.bufferLength], e.buffer)
		copy(e.buffer, a[:e.bufferLength])
		e.mergeSort(e.bufferLength, n, 0, minRun(n), e.bufferLength)
		e.mergeFromBuffer(0, e.bufferLength, n, e.bufferLength)
		return
	}
	start, end := e.bufferLength, n
	dataLength := end - start
	copy(e.buffer, a[start:start+e.bufferLength])
	e.mergeSort(0, start, start, minRun(e.bufferLength), e.bufferLength)
	copy(a[start:start+e.bufferLength], e.buffer)
	copy(e.buffer, a[:e.bufferLength])
	run := e.mergeSort(start, end, 0, minRun(n), e.bufferLength)
	backward := false
	for run < dataLength {
		index := start
		for index+2*run <= end {
			e.ectaForward(index, index+run, index+2*run)
			index += 2 * run
		}
		if index+run < end {
			e.ectaForward(index, index+run, end)
		} else {
			e.copyMain(index, index-2*e.block, end-index)
		}
		run *= 2
		start -= 2 * e.block
		end -= 2 * e.block
		if run >= dataLength {
			backward = true
			break
		}
		index = start
		for index+2*run <= end {
			index += 2 * run
		}
		if index+run < end {
			e.ectaBackward(index, index+run, end)
		} else {
			e.copyMain(index, index+2*e.block, end-index)
		}
		index -= 2 * run
		for index >= start {
			e.ectaBackward(index, index+run, index+2*run)
			index -= 2 * run
		}
		run *= 2
		start += 2 * e.block
		end += 2 * e.block
	}
	if backward {
		e.dualMergeBackward(0, start, end, n, e.bufferLength)
	} else {
		e.mergeFromBuffer(0, start, end, e.bufferLength)
	}
}
func main() {
	a := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	sort(a)
	fmt.Print("[")
	for i, value := range a {
		if i > 0 { fmt.Print(", ") }
		fmt.Print(value)
	}
	fmt.Println("]")
}
