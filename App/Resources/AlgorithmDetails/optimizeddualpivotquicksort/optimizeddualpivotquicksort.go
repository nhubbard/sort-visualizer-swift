package main

import (
	"fmt"
)

func insertionSort(arr []int, left, right int) {
	for i := left + 1; i <= right; i++ {
		for j := i; j > left && arr[j] < arr[j-1]; j-- {
			arr[j], arr[j-1] = arr[j-1], arr[j]
		}
	}
}

func optimizedDualPivotQuickSort(arr []int, left, right, divisor int) {
	length := right - left
	if length < 27 {
		insertionSort(arr, left, right)
		return
	}
	third := length / divisor
	med1, med2 := left+third, right-third
	if med1 <= left {
		med1 = left + 1
	}
	if med2 >= right {
		med2 = right - 1
	}
	if arr[med1] < arr[med2] {
		arr[med1], arr[left] = arr[left], arr[med1]
		arr[med2], arr[right] = arr[right], arr[med2]
	} else {
		arr[med1], arr[right] = arr[right], arr[med1]
		arr[med2], arr[left] = arr[left], arr[med2]
	}
	pivot1, pivot2 := arr[left], arr[right]
	less, great := left+1, right-1
	for k := less; k <= great; k++ {
		if arr[k] < pivot1 {
			arr[k], arr[less] = arr[less], arr[k]
			less++
		} else if arr[k] > pivot2 {
			for k < great && arr[great] > pivot2 {
				great--
			}
			arr[k], arr[great] = arr[great], arr[k]
			great--
			if arr[k] < pivot1 {
				arr[k], arr[less] = arr[less], arr[k]
				less++
			}
		}
	}
	dist := great - less
	if dist < 13 {
		divisor++
	}
	arr[less-1], arr[left] = arr[left], arr[less-1]
	arr[great+1], arr[right] = arr[right], arr[great+1]
	optimizedDualPivotQuickSort(arr, left, less-2, divisor)
	optimizedDualPivotQuickSort(arr, great+2, right, divisor)
	if dist > length-13 && pivot1 != pivot2 {
		for k := less; k <= great; k++ {
			if arr[k] == pivot1 {
				arr[k], arr[less] = arr[less], arr[k]
				less++
			} else if arr[k] == pivot2 {
				arr[k], arr[great] = arr[great], arr[k]
				great--
				if arr[k] == pivot1 {
					arr[k], arr[less] = arr[less], arr[k]
					less++
				}
			}
		}
	}
	if pivot1 < pivot2 {
		optimizedDualPivotQuickSort(arr, less, great, divisor)
	}
}

func sort(arr []int) []int {
	if len(arr) > 1 {
		optimizedDualPivotQuickSort(arr, 0, len(arr)-1, 3)
	}
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
		21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
	}
	fmt.Println(sort(array))
}
