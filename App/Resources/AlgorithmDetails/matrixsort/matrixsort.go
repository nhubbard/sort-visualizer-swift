package main

import (
	"fmt"
	"math"
)

type matrixShape struct {
	width      int
	insertLast bool
}

func dirCompareVal(left, right int, dir bool) int {
	var res int
	if left > right {
		res = 1
	} else if left < right {
		res = -1
	} else {
		res = 0
	}
	if dir {
		return res
	}
	return -res
}

func gapReverse(arr []int, start, end, gap int) {
	i, j := start, end
	for i < j {
		arr[i], arr[j-gap] = arr[j-gap], arr[i]
		i += gap
		j -= gap
	}
}

func insertLast(arr []int, a, b, gap int, dir bool) bool {
	did := false
	key := arr[b]
	j := b - gap
	for j >= a && dirCompareVal(key, arr[j], dir) < 0 {
		arr[j+gap] = arr[j]
		did = true
		j -= gap
	}
	arr[j+gap] = key
	return did
}

func getMatrixDims(length int) matrixShape {
	dim := int(math.Sqrt(float64(length)))
	insertLastFlag := dim*dim == length-1
	for length%dim != 0 {
		dim--
	}
	width := dim
	height := length / dim
	unbalanced := (width == 1) != (height == 1)
	return matrixShape{width: width, insertLast: unbalanced || insertLastFlag}
}

func matrixSort(arr []int, start, end, gap int, dir bool) bool {
	length := (end - start) / gap
	if length < 2 {
		return false
	} else if length <= 16 {
		did := false
		i := start
		for i < end {
			did = insertLast(arr, start, i, gap, dir) || did
			i += gap
		}
		return did
	}

	matShape := getMatrixDims(length)
	if matShape.insertLast {
		did1 := matrixSort(arr, start, end-gap, gap, dir)
		did2 := insertLast(arr, start, end-gap, gap, dir)
		return did1 || did2
	}

	i := start + matShape.width*gap
	for i < end {
		gapReverse(arr, i, i+matShape.width*gap, gap)
		i += 2 * matShape.width * gap
	}

	did := false
	newdid := true
	for newdid {
		newdid = false
		curdir := dir
		i = start
		for i < end {
			newdid = matrixSort(arr, i, i+matShape.width*gap, gap, curdir) || newdid
			did = did || newdid
			curdir = !curdir
			i += matShape.width * gap
		}

		newdid = false
		for k := 0; k < matShape.width; k++ {
			newdid = matrixSort(arr, start+k*gap, end+k*gap, gap*matShape.width, dir) || newdid
			did = did || newdid
		}
	}
	i = start + matShape.width*gap
	for i < end {
		gapReverse(arr, i, i+matShape.width*gap, gap)
		i += 2 * matShape.width * gap
	}

	return did
}

func sort(arr []int) []int {
	matrixSort(arr, 0, len(arr), 1, true)
	return arr
}

func main() {
	array := []int{15, 3, 22, 8, 19, 1, 24, 11, 6, 20,
		9, 17, 2, 14, 23, 5, 18, 0, 12, 21,
		7, 16, 4, 13, 10}
	fmt.Println(sort(array))
}
