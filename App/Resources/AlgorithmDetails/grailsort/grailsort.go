package main

import (
	"fmt"
)

func swap(arr []int, a int, b int) {
	arr[a], arr[b] = arr[b], arr[a]
}

func compareValues(a int, b int) int {
	if a > b {
		return 1
	}
	if a < b {
		return -1
	}
	return 0
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

func findKeys(arr []int, pos int, length int, numKeys int) int {
	dist := 1
	foundKeys := 1
	firstKey := 0
	for dist < length && foundKeys < numKeys {
		loc := binSearch(arr, pos+firstKey, foundKeys, pos+dist, true)
		if loc == foundKeys || arr[pos+dist] != arr[pos+firstKey+loc] {
			rotate(arr, pos+firstKey, foundKeys, dist-(firstKey+foundKeys))
			firstKey = dist - foundKeys
			rotate(arr, pos+(firstKey+loc), foundKeys-loc, 1)
			foundKeys++
		}
		dist++
	}
	rotate(arr, pos, firstKey, foundKeys)
	return foundKeys
}

func mergeWithoutBuffer(arr []int, pos int, len1 int, len2 int) {
	if len1 == 0 || len2 == 0 {
		return
	}
	if len1 < len2 {
		for len1 != 0 {
			loc := binSearch(arr, pos+len1, len2, pos, true)
			if loc != 0 {
				rotate(arr, pos, len1, loc)
				pos += loc
				len2 -= loc
			}
			if len2 == 0 {
				break
			}
			for {
				pos++
				len1--
				if !(len1 != 0 && arr[pos] <= arr[pos+len1]) {
					break
				}
			}
		}
	} else {
		for len2 != 0 {
			loc := binSearch(arr, pos, len1, pos+len1+len2-1, false)
			if loc != len1 {
				rotate(arr, pos+loc, len1-loc, len2)
				len1 = loc
			}
			if len1 == 0 {
				break
			}
			for {
				len2--
				if !(len2 != 0 && arr[pos+len1-1] <= arr[pos+len1+len2-1]) {
					break
				}
			}
		}
	}
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

func smartMergeWithoutBuffer(arr []int, pos int, leftOverLen int, leftOverFrag int, regBlockLen int) (int, int) {
	if regBlockLen == 0 {
		return leftOverLen, leftOverFrag
	}
	len1 := leftOverLen
	len2 := regBlockLen
	typeFrag := 1 - leftOverFrag
	if len1 != 0 && (compareValues(arr[pos+len1-1], arr[pos+len1])-typeFrag) >= 0 {
		for len1 != 0 {
			isLeft := typeFrag != 0
			foundLen := binSearch(arr, pos+len1, len2, pos, isLeft)
			if foundLen != 0 {
				rotate(arr, pos, len1, foundLen)
				pos += foundLen
				len2 -= foundLen
			}
			if len2 == 0 {
				return len1, leftOverFrag
			}
			for {
				pos++
				len1--
				if !(len1 != 0 && (compareValues(arr[pos], arr[pos+len1])-typeFrag) < 0) {
					break
				}
			}
		}
	}
	return len2, typeFrag
}

func smartMergeWithBuffer(arr []int, pos int, leftOverLen int, leftOverFrag int, blockLen int) (int, int) {
	dist := -blockLen
	left := 0
	right := leftOverLen
	leftEnd := right
	rightEnd := right + blockLen
	typeFrag := 1 - leftOverFrag
	for left < leftEnd && right < rightEnd {
		if (compareValues(arr[pos+left], arr[pos+right]) - typeFrag) < 0 {
			swap(arr, pos+dist, pos+left)
			dist++
			left++
		} else {
			swap(arr, pos+dist, pos+right)
			dist++
			right++
		}
	}
	var length int
	fragment := leftOverFrag
	if left < leftEnd {
		length = leftEnd - left
		for left < leftEnd {
			leftEnd--
			rightEnd--
			swap(arr, pos+leftEnd, pos+rightEnd)
		}
	} else {
		length = rightEnd - right
		fragment = typeFrag
	}
	return length, fragment
}

func mergeBuffersLeft(arr []int, keysPos int, midkey int, pos int, blockCount int, blockLen int,
	havebuf bool, aBlockCount int, lastLen int) {
	if blockCount == 0 {
		aBlocksLen := aBlockCount * blockLen
		if havebuf {
			mergeLeft(arr, pos, aBlocksLen, lastLen, -blockLen)
		} else {
			mergeWithoutBuffer(arr, pos, aBlocksLen, lastLen)
		}
		return
	}
	leftOverLen := blockLen
	leftOverFrag := 0
	if arr[keysPos] >= arr[midkey] {
		leftOverFrag = 1
	}
	processIndex := blockLen
	for keyIndex := 1; keyIndex < blockCount; keyIndex++ {
		restToProcess := processIndex - leftOverLen
		nextFrag := 0
		if arr[keysPos+keyIndex] >= arr[midkey] {
			nextFrag = 1
		}
		if nextFrag == leftOverFrag {
			if havebuf {
				multiSwap(arr, pos+restToProcess-blockLen, pos+restToProcess, leftOverLen)
			}
			restToProcess = processIndex
			leftOverLen = blockLen
		} else {
			if havebuf {
				leftOverLen, leftOverFrag = smartMergeWithBuffer(arr, pos+restToProcess, leftOverLen, leftOverFrag, blockLen)
			} else {
				leftOverLen, leftOverFrag = smartMergeWithoutBuffer(arr, pos+restToProcess, leftOverLen, leftOverFrag, blockLen)
			}
		}
		processIndex += blockLen
	}
	restToProcess := processIndex - leftOverLen
	if lastLen != 0 {
		if leftOverFrag != 0 {
			if havebuf {
				multiSwap(arr, pos+restToProcess-blockLen, pos+restToProcess, leftOverLen)
			}
			restToProcess = processIndex
			leftOverLen = blockLen * aBlockCount
			leftOverFrag = 0
		} else {
			leftOverLen += blockLen * aBlockCount
		}
		if havebuf {
			mergeLeft(arr, pos+restToProcess, leftOverLen, lastLen, -blockLen)
		} else {
			mergeWithoutBuffer(arr, pos+restToProcess, leftOverLen, lastLen)
		}
	} else {
		if havebuf {
			multiSwap(arr, pos+restToProcess, pos+restToProcess-blockLen, leftOverLen)
		}
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

func combineBlocks(arr []int, keyPos int, pos int, length int, buildLen int, regBlockLen int, havebuf bool) {
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
		extraKey := 0
		if i == combineLen {
			blockCountSrc = leftOver
			extraKey = 1
		}
		blockCount := blockCountSrc / regBlockLen
		insertSort(arr, keyPos, blockCount+extraKey)
		midkey := buildLen / regBlockLen
		for index := 1; index < blockCount; index++ {
			leftIndex := index - 1
			for rightIndex := index; rightIndex < blockCount; rightIndex++ {
				a := arr[blockPos+leftIndex*regBlockLen]
				b := arr[blockPos+rightIndex*regBlockLen]
				if a > b || (a == b && arr[keyPos+leftIndex] > arr[keyPos+rightIndex]) {
					leftIndex = rightIndex
				}
			}
			if leftIndex != index-1 {
				multiSwap(arr, blockPos+(index-1)*regBlockLen, blockPos+leftIndex*regBlockLen, regBlockLen)
				swap(arr, keyPos+(index-1), keyPos+leftIndex)
				if midkey == index-1 || midkey == leftIndex {
					midkey ^= (index - 1) ^ leftIndex
				}
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
		mergeBuffersLeft(arr, keyPos, keyPos+midkey, blockPos, blockCount-aBlockCount, regBlockLen, havebuf, aBlockCount, lastLen)
	}
	if havebuf {
		for length > 0 {
			length--
			swap(arr, pos+length, pos+length-regBlockLen)
		}
	}
}

func lazyStableSort(arr []int, pos int, length int) {
	for dist := 1; dist < length; dist += 2 {
		if arr[pos+dist-1] > arr[pos+dist] {
			swap(arr, pos+dist-1, pos+dist)
		}
	}
	part := 2
	for part < length {
		left := 0
		right := length - 2*part
		for left <= right {
			mergeWithoutBuffer(arr, pos+left, part, part)
			left += 2 * part
		}
		rest := length - left
		if rest > part {
			mergeWithoutBuffer(arr, pos+left, part, rest-part)
		}
		part *= 2
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
	numKeys := (length-1)/blockLen + 1
	keysFound := findKeys(arr, pos, length, numKeys+blockLen)
	bufferEnabled := true
	if keysFound < numKeys+blockLen {
		if keysFound < 4 {
			lazyStableSort(arr, pos, length)
			return
		}
		numKeys = blockLen
		for numKeys > keysFound {
			numKeys /= 2
		}
		bufferEnabled = false
		blockLen = 0
	}
	dist := blockLen + numKeys
	buildLen := blockLen
	if !bufferEnabled {
		buildLen = numKeys
	}
	buildBlocks(arr, pos+dist, length-dist, buildLen)
	for {
		buildLen *= 2
		if length-dist <= buildLen {
			break
		}
		regBlockLen := blockLen
		buildBufEnabled := bufferEnabled
		if !bufferEnabled {
			if numKeys > 4 && (numKeys/8)*numKeys >= buildLen {
				regBlockLen = numKeys / 2
				buildBufEnabled = true
			} else {
				calcKeys := 1
				i := buildLen * keysFound / 2
				for calcKeys < numKeys && i != 0 {
					calcKeys *= 2
					i /= 8
				}
				regBlockLen = (2 * buildLen) / calcKeys
			}
		}
		combineBlocks(arr, pos, pos+dist, length-dist, buildLen, regBlockLen, buildBufEnabled)
	}
	insertSort(arr, pos, dist)
	mergeWithoutBuffer(arr, pos, dist, length-dist)
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
