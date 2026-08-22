package main

import (
	"fmt"
	"math"
)

const empty = math.MinInt

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	capacity := 0
	var slots []int
	// Physical `slots` index of each placed element, ascending by both position and value.
	var positions []int

	insertAt := func(index int, value int) {
		positions = append(positions, 0)
		copy(positions[index+1:], positions[index:])
		positions[index] = value
	}

	rebalance := func() {
		count := len(positions)
		newCapacity := count * 2
		if newCapacity < 2 {
			newCapacity = 2
		}
		newSlots := make([]int, newCapacity)
		for i := range newSlots {
			newSlots[i] = empty
		}
		newPositions := make([]int, 0, count)
		for i, pos := range positions {
			newPos := i * 2
			newSlots[newPos] = slots[pos]
			newPositions = append(newPositions, newPos)
		}
		slots = newSlots
		positions = newPositions
		capacity = newCapacity
	}

	insert := func(value int) {
		if len(positions) == capacity {
			rebalance()
		}

		// Upper-bound binary search: first slot whose value is strictly greater than `value`.
		lo, hi := 0, len(positions)
		for lo < hi {
			mid := (lo + hi) / 2
			if slots[positions[mid]] > value {
				hi = mid
			} else {
				lo = mid + 1
			}
		}
		k := lo
		targetPos := 0
		if k != 0 {
			targetPos = positions[k-1] + 1
		}

		if !(targetPos == capacity || slots[targetPos] != empty) {
			slots[targetPos] = value
			insertAt(k, targetPos)
			return
		}

		// Either targetPos is already occupied, or targetPos == capacity (new maximum, no room
		// left of the structure's end). Search BOTH directions for the nearest gap and shift
		// whichever side is closer.
		leftGap := targetPos - 1
		for leftGap >= 0 && slots[leftGap] != empty {
			leftGap--
		}
		rightGap := targetPos
		for rightGap < capacity && slots[rightGap] != empty {
			rightGap++
		}
		leftDistance := math.MaxInt
		if leftGap >= 0 {
			leftDistance = targetPos - leftGap
		}
		rightDistance := math.MaxInt
		if rightGap < capacity {
			rightDistance = rightGap - targetPos
		}

		if rightDistance <= leftDistance {
			i := rightGap
			for i > targetPos {
				slots[i] = slots[i-1]
				i--
			}
			for idx := k; idx < k+(rightGap-targetPos); idx++ {
				positions[idx]++
			}
			slots[targetPos] = value
			insertAt(k, targetPos)
		} else {
			shiftCount := (targetPos - 1) - leftGap
			i := leftGap
			for i < targetPos-1 {
				slots[i] = slots[i+1]
				i++
			}
			for idx := k - shiftCount; idx < k; idx++ {
				positions[idx]--
			}
			slots[targetPos-1] = value
			insertAt(k, targetPos-1)
		}
	}

	for _, v := range arr {
		insert(v)
	}

	result := make([]int, n)
	for i, pos := range positions {
		result[i] = slots[pos]
	}
	return result
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
