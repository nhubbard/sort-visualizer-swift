package main

import (
	"fmt"
)

func swap(arr []int, a int, b int) {
	arr[a], arr[b] = arr[b], arr[a]
}

func multiSwap(arr []int, a int, b int, count int) {
	for i := 0; i < count; i++ {
		swap(arr, a+i, b+i)
	}
}

func rotate(arr []int, pos int, lenA int, lenB int) {
	for lenA != 0 && lenB != 0 {
		if lenA <= lenB {
			multiSwap(arr, pos, pos+lenA, lenA)
			pos += lenA
			lenB -= lenA
		} else {
			multiSwap(arr, pos+(lenA-lenB), pos+lenA, lenB)
			lenA -= lenB
		}
	}
}

func insertSort(arr []int, pos int, length int) {
	for i := 1; i < length; i++ {
		j := pos + i
		for j > pos && arr[j] < arr[j-1] {
			swap(arr, j, j-1)
			j--
		}
	}
}

func binSearch(arr []int, pos int, length int, keyPos int, isLeft bool) int {
	left := -1
	right := length
	key := arr[keyPos]
	for left < right-1 {
		mid := left + (right-left)/2
		var cond bool
		if isLeft {
			cond = arr[pos+mid] >= key
		} else {
			cond = arr[pos+mid] > key
		}
		if cond {
			right = mid
		} else {
			left = mid
		}
	}
	return right
}

func mergeWithoutBuffer(arr []int, pos int, len1 int, len2 int) {
	if len1 == 0 || len2 == 0 {
		return
	}
	if len1+len2 == 2 {
		if arr[pos] > arr[pos+1] {
			swap(arr, pos, pos+1)
		}
		return
	}
	var mid1, mid2 int
	if len1 > len2 {
		mid1 = len1 / 2
		mid2 = binSearch(arr, pos+len1, len2, pos+mid1, true)
	} else {
		mid2 = len2 / 2
		mid1 = binSearch(arr, pos, len1, pos+len1+mid2, false)
	}
	rotate(arr, pos+mid1, len1-mid1, mid2)
	mergeWithoutBuffer(arr, pos, mid1, mid2)
	mergeWithoutBuffer(arr, pos+mid1+mid2, len1-mid1, len2-mid2)
}

func mergeLeft(arr []int, pos int, leftLen int, rightLen int, dist int) {
	left := 0
	right := leftLen
	rightLen += leftLen
	for right < rightLen {
		if left == leftLen || arr[pos+left] > arr[pos+right] {
			swap(arr, pos+dist, pos+right)
			dist++
			right++
		} else {
			swap(arr, pos+dist, pos+left)
			dist++
			left++
		}
	}
	if dist != left {
		multiSwap(arr, pos+dist, pos+left, leftLen-left)
	}
}

func mergeRight(arr []int, pos int, leftLen int, rightLen int, dist int) {
	mergedPos := leftLen + rightLen + dist - 1
	right := leftLen + rightLen - 1
	left := leftLen - 1
	for left >= 0 {
		if right < leftLen || arr[pos+left] > arr[pos+right] {
			swap(arr, pos+mergedPos, pos+left)
			mergedPos--
			left--
		} else {
			swap(arr, pos+mergedPos, pos+right)
			mergedPos--
			right--
		}
	}
	for right != mergedPos && right >= leftLen {
		swap(arr, pos+mergedPos, pos+right)
		mergedPos--
		right--
	}
}

func smartMergeWithBuffer(arr []int, pos int, leftOverLen int, blockLen int) int {
	dist := -blockLen
	left := 0
	right := leftOverLen
	leftEnd := right
	rightEnd := right + blockLen
	var length int
	for left < leftEnd && right < rightEnd {
		if arr[pos+left] <= arr[pos+right] {
			swap(arr, pos+dist, pos+left)
			dist++
			left++
		} else {
			swap(arr, pos+dist, pos+right)
			dist++
			right++
		}
	}
	if left < leftEnd {
		length = leftEnd - left
		for left < leftEnd {
			leftEnd--
			rightEnd--
			swap(arr, pos+leftEnd, pos+rightEnd)
		}
	} else {
		length = rightEnd - right
	}
	return length
}

func mergeBuffersLeft(arr []int, pos int, blockCount int, blockLen int, aBlockCount int, lastLen int) {
	if blockCount == 0 {
		mergeLeft(arr, pos, aBlockCount*blockLen, lastLen, -blockLen)
		return
	}
	leftOverLen := blockLen
	processIndex := blockLen
	for keyIndex := 1; keyIndex < blockCount; keyIndex++ {
		restToProcess := processIndex - leftOverLen
		leftOverLen = smartMergeWithBuffer(arr, pos+restToProcess, leftOverLen, blockLen)
		processIndex += blockLen
	}
	restToProcess := processIndex - leftOverLen
	if lastLen != 0 {
		leftOverLen += blockLen * aBlockCount
		mergeLeft(arr, pos+restToProcess, leftOverLen, lastLen, -blockLen)
	} else {
		multiSwap(arr, pos+restToProcess, pos+restToProcess-blockLen, leftOverLen)
	}
}

func buildBlocks(arr []int, pos int, length int, buildLen int) {
	for dist := 1; dist < length; dist += 2 {
		extraDist := 0
		if arr[pos+dist-1] > arr[pos+dist] {
			extraDist = 1
		}
		swap(arr, pos+dist-3, pos+dist-1+extraDist)
		swap(arr, pos+dist-2, pos+dist-extraDist)
	}
	if length%2 == 1 {
		swap(arr, pos+length-1, pos+length-3)
	}
	pos -= 2
	part := 2
	for part < buildLen {
		left := 0
		right := length - 2*part
		for left <= right {
			mergeLeft(arr, pos+left, part, part, -part)
			left += 2 * part
		}
		rest := length - left
		if rest > part {
			mergeLeft(arr, pos+left, part, rest-part, -part)
		} else {
			rotate(arr, pos+left-part, part, rest)
		}
		pos -= part
		part *= 2
	}
	restToBuild := length % (2 * buildLen)
	leftOverPos := length - restToBuild
	if restToBuild <= buildLen {
		rotate(arr, pos+leftOverPos, restToBuild, buildLen)
	} else {
		mergeRight(arr, pos+leftOverPos, buildLen, restToBuild-buildLen, buildLen)
	}
	for leftOverPos > 0 {
		leftOverPos -= 2 * buildLen
		mergeRight(arr, pos+leftOverPos, buildLen, buildLen, buildLen)
	}
}

func combineBlocks(arr []int, pos int, length int, buildLen int, regBlockLen int) {
	combineLen := length / (2 * buildLen)
	leftOver := length % (2 * buildLen)
	if leftOver <= buildLen {
		length -= leftOver
		leftOver = 0
	}
	for i := 0; i <= combineLen; i++ {
		if i == combineLen && leftOver == 0 {
			break
		}
		blockPos := pos + i*2*buildLen
		blockCountSrc := 2 * buildLen
		if i == combineLen {
			blockCountSrc = leftOver
		}
		blockCount := blockCountSrc / regBlockLen
		for index := 1; index < blockCount; index++ {
			leftIndex := index - 1
			for rightIndex := index; rightIndex < blockCount; rightIndex++ {
				a := arr[blockPos+leftIndex*regBlockLen]
				b := arr[blockPos+rightIndex*regBlockLen]
				cmp := 0
				if a > b {
					cmp = 1
				} else if a < b {
					cmp = -1
				}
				if cmp > 0 || (cmp == 0 && arr[blockPos+(leftIndex+1)*regBlockLen-1] > arr[blockPos+(rightIndex+1)*regBlockLen-1]) {
					leftIndex = rightIndex
				}
			}
			if leftIndex != index-1 {
				multiSwap(arr, blockPos+(index-1)*regBlockLen, blockPos+leftIndex*regBlockLen, regBlockLen)
			}
		}
		aBlockCount := 0
		lastLen := 0
		if i == combineLen {
			lastLen = leftOver % regBlockLen
		}
		if lastLen != 0 {
			for aBlockCount < blockCount && arr[blockPos+blockCount*regBlockLen] < arr[blockPos+(blockCount-aBlockCount-1)*regBlockLen] {
				aBlockCount++
			}
		}
		mergeBuffersLeft(arr, blockPos, blockCount-aBlockCount, regBlockLen, aBlockCount, lastLen)
	}
	for length > 0 {
		length--
		swap(arr, pos+length, pos+length-regBlockLen)
	}
}

func commonSort(arr []int, pos int, length int) {
	if length <= 16 {
		insertSort(arr, pos, length)
		return
	}
	blockLen := 1
	for blockLen*blockLen < length {
		blockLen *= 2
	}
	buildLen := blockLen
	buildBlocks(arr, pos+blockLen, length-blockLen, buildLen)
	for {
		buildLen *= 2
		if length-blockLen <= buildLen {
			break
		}
		combineBlocks(arr, pos+blockLen, length-blockLen, buildLen, blockLen)
	}
	insertSort(arr, pos, blockLen)
	mergeWithoutBuffer(arr, pos, blockLen, length-blockLen)
}

func sort(arr []int) []int {
	n := len(arr)
	commonSort(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
