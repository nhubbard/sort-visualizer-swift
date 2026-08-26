package main

import (
	"fmt"
)

const recency = 8
const earlyOutTestAt = 4
const earlyOutDisorderFraction = 0.6

// quicksort is a plain general-purpose sort for arr[lo:hi], used both as the early-out fallback
// and to sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
// works here -- the algorithm doesn't depend on which one.
func quicksort(arr []int, lo int, hi int) {
	if hi-lo <= 1 {
		return
	}
	pivot := arr[lo+(hi-lo)/2]
	less := []int{}
	equal := []int{}
	greater := []int{}

	for i := lo; i < hi; i++ {
		if arr[i] < pivot {
			less = append(less, arr[i])
		} else if arr[i] > pivot {
			greater = append(greater, arr[i])
		} else {
			equal = append(equal, arr[i])
		}
	}

	quicksort(less, 0, len(less))
	quicksort(greater, 0, len(greater))

	k := lo
	for _, value := range less {
		arr[k] = value
		k++
	}
	for _, value := range equal {
		arr[k] = value
		k++
	}
	for _, value := range greater {
		arr[k] = value
		k++
	}
}

func sort(arr []int) []int {
	length := len(arr)
	if length < 2 {
		return arr
	}

	dropped := []int{}
	numDroppedInARow := 0
	read := 0
	write := 0
	iteration := 0
	earlyOutStop := length / earlyOutTestAt

	for read < length {
		iteration++
		if iteration == earlyOutStop && float64(len(dropped)) > float64(read)*earlyOutDisorderFraction {
			// Too disordered for the adaptive approach to be worth it: flush what's been
			// dropped so far back into the array and fall back to a plain full sort.
			for _, value := range dropped {
				arr[write] = value
				write++
			}
			dropped = dropped[:0]
			quicksort(arr, 0, length)
			return arr
		}

		if write == 0 || arr[read] >= arr[write-1] {
			// In order -- keep it.
			arr[write] = arr[read]
			write++
			read++
			numDroppedInARow = 0
		} else if numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write-2] {
			// Quick undo: the element two back would have accepted this one just fine, so
			// drop the one right before it instead of the new element.
			dropped = append(dropped, arr[write-1])
			arr[write-1] = arr[read]
			read++
		} else if numDroppedInARow < recency {
			dropped = append(dropped, arr[read])
			read++
			numDroppedInARow++
		} else {
			// Accepting something numDroppedInARow elements back made every subsequent
			// element drop -- that accept was a mistake. Undo it, and any other recently
			// accepted elements bigger than the dropped run's maximum.
			dropped = dropped[:len(dropped)-numDroppedInARow]
			read -= numDroppedInARow

			numBacktracked := 1
			write--

			maxOfDropped := arr[read]
			for i := read + 1; i <= read+numDroppedInARow; i++ {
				if arr[i] > maxOfDropped {
					maxOfDropped = arr[i]
				}
			}

			for write >= 1 && maxOfDropped < arr[write-1] {
				write--
				numBacktracked++
			}

			for i := write; i < write+numBacktracked; i++ {
				dropped = append(dropped, arr[i])
			}

			numDroppedInARow = 0
		}
	}

	for offset, value := range dropped {
		arr[write+offset] = value
	}

	quicksort(arr, write, length)

	// Copy the now-sorted dropped tail before the final backward merge starts overwriting
	// arr[write:] in place.
	buffer := make([]int, len(dropped))
	copy(buffer, arr[write:write+len(dropped)])

	i := len(buffer) - 1
	j := write - 1
	k := length - 1

	for i >= 0 {
		if j < 0 || buffer[i] > arr[j] {
			arr[k] = buffer[i]
			k--
			i--
		} else {
			arr[k] = arr[j]
			k--
			j--
		}
	}

	return arr
}

func main() {
	array := []int{
		0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
		21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
	}
	fmt.Println(sort(array))
}
