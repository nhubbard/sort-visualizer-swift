package main

import (
	"fmt"
)

type stackID int

const (
	stackTwo stackID = iota
	stackThree
)

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	var stack2 []int
	var stack3 []int

	push := func(id stackID, value int) {
		if id == stackTwo {
			stack2 = append(stack2, value)
		} else {
			stack3 = append(stack3, value)
		}
	}

	pop := func(id stackID) int {
		if id == stackTwo {
			value := stack2[len(stack2)-1]
			stack2 = stack2[:len(stack2)-1]
			return value
		}
		value := stack3[len(stack3)-1]
		stack3 = stack3[:len(stack3)-1]
		return value
	}

	peek := func(id stackID) int {
		if id == stackTwo {
			return stack2[len(stack2)-1]
		}
		return stack3[len(stack3)-1]
	}

	isEmpty := func(id stackID) bool {
		if id == stackTwo {
			return len(stack2) == 0
		}
		return len(stack3) == 0
	}

	sp := 0
	unsorted := 0
	target := 0
	targetMoves := 0

	moveFromMain := func(id stackID, checkUnsorted bool) int {
		duplicates := 1
		push(id, arr[sp])
		sp++
		endOnLength := sp >= n || (checkUnsorted && sp >= unsorted)
		for !endOnLength && arr[sp] == peek(id) {
			duplicates++
			push(id, arr[sp])
			sp++
			endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
		}
		return duplicates
	}

	moveToMain := func(id stackID) {
		sp--
		arr[sp] = pop(id)
		for !isEmpty(id) && peek(id) == arr[sp] {
			sp--
			arr[sp] = pop(id)
		}
	}

	moveBetweenStacks := func(from stackID, to stackID) {
		push(to, pop(from))
		for !isEmpty(from) && peek(from) == peek(to) {
			push(to, pop(from))
		}
	}

	var validNumberMoves func(moves int) bool
	validNumberMoves = func(moves int) bool {
		if moves == 0 {
			return true
		}
		if moves%2 == 0 {
			return false
		}
		return validNumberMoves(moves / 2)
	}

	var getHeight func(movesPlus1 int) int
	getHeight = func(movesPlus1 int) int {
		if movesPlus1 == 1 {
			return 0
		}
		return getHeight(movesPlus1/2) + 1
	}

	endConMet := func(endCon int, moves int) bool {
		if !validNumberMoves(moves) {
			return false
		}
		switch endCon {
		case 1:
			return len(stack2) == 0 || target <= stack2[len(stack2)-1]
		case 2:
			return moves == targetMoves
		case 3:
			return len(stack2) == 0
		default:
			panic("unknown end condition")
		}
	}

	hanoi := func(startStack int, goRight bool, endCon int) int {
		moves := 0
		minPoleLoc := startStack

		if !endConMet(endCon, moves) {
			moves++
			switch minPoleLoc {
			case 1:
				if goRight {
					moveFromMain(stackTwo, true)
					minPoleLoc = 2
				} else {
					moveFromMain(stackThree, true)
					minPoleLoc = 3
				}
			case 2:
				if goRight {
					moveBetweenStacks(stackTwo, stackThree)
					minPoleLoc = 3
				} else {
					moveToMain(stackTwo)
					minPoleLoc = 1
				}
			default:
				if goRight {
					moveToMain(stackThree)
					minPoleLoc = 1
				} else {
					moveBetweenStacks(stackThree, stackTwo)
					minPoleLoc = 2
				}
			}
		}

		for !endConMet(endCon, moves) {
			moves += 2
			switch minPoleLoc {
			case 1:
				if len(stack2) > 0 && (len(stack3) == 0 || stack2[len(stack2)-1] < stack3[len(stack3)-1]) {
					moveBetweenStacks(stackTwo, stackThree)
				} else {
					moveBetweenStacks(stackThree, stackTwo)
				}
				if goRight {
					moveFromMain(stackTwo, true)
					minPoleLoc = 2
				} else {
					moveFromMain(stackThree, true)
					minPoleLoc = 3
				}
			case 2:
				if len(stack3) == 0 || (sp < unsorted && arr[sp] < stack3[len(stack3)-1]) {
					moveFromMain(stackThree, true)
				} else {
					moveToMain(stackThree)
				}
				if goRight {
					moveBetweenStacks(stackTwo, stackThree)
					minPoleLoc = 3
				} else {
					moveToMain(stackTwo)
					minPoleLoc = 1
				}
			default:
				if len(stack2) == 0 || (sp < unsorted && arr[sp] < stack2[len(stack2)-1]) {
					moveFromMain(stackTwo, true)
				} else {
					moveToMain(stackTwo)
				}
				if goRight {
					moveToMain(stackThree)
					minPoleLoc = 1
				} else {
					moveBetweenStacks(stackThree, stackTwo)
					minPoleLoc = 2
				}
			}
		}

		return moves
	}

	removeFromMainStack := func() {
		target = arr[sp]
		moves := hanoi(2, true, 1)
		height := getHeight(moves + 1)
		targetMoves = moves
		evenHeight := height%2 == 0

		if evenHeight {
			hanoi(1, true, 2)
		}
		unsorted += moveFromMain(stackTwo, false)
		hanoi(3, evenHeight, 2)
	}

	returnToMainStack := func() {
		moves := hanoi(2, true, 3)
		height := getHeight(moves + 1)
		if height%2 == 1 {
			targetMoves = moves
			hanoi(3, true, 2)
		}
	}

	for unsorted < n {
		removeFromMainStack()
	}
	returnToMainStack()

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
