package main

import (
	"fmt"
)

// A ref is either a player leaf, encoded as -playerIndex (so ref <= 0), or another match
// node's root offset into matches (so ref > 0).
func isPlayer(ref int) bool {
	return ref <= 0
}

func makePlayer(index int) int {
	return -index
}

func absInt(value int) int {
	if value < 0 {
		return -value
	}
	return value
}

func getWinner(matches []int, root int) int {
	return matches[root]
}

func getWinners(matches []int, root int) int {
	return matches[root+1]
}

func getLosers(matches []int, root int) int {
	return matches[root+2]
}

func setMatch(matches []int, root, winner, winners, losers int) {
	matches[root] = winner
	matches[root+1] = winners
	matches[root+2] = losers
}

func getPlayer(array, matches []int, ref int) int {
	if isPlayer(ref) {
		return absInt(ref)
	}
	return getWinner(matches, ref)
}

func makeMatch(array, matches []int, top, bot, root int) int {
	topWinner := getPlayer(array, matches, top)
	botWinner := getPlayer(array, matches, bot)
	if array[topWinner] <= array[botWinner] {
		setMatch(matches, root, topWinner, top, bot)
	} else {
		setMatch(matches, root, botWinner, bot, top)
	}
	return root
}

func knockout(array, matches []int, i, k, root int) int {
	if i == k {
		return makePlayer(i)
	}
	mid := (i + k) / 2
	leftRef := knockout(array, matches, i, mid, 2*root)
	rightRef := knockout(array, matches, mid+1, k, 2*root+3)
	return makeMatch(array, matches, leftRef, rightRef, root)
}

func rebuild(array, matches []int, root int) int {
	if isPlayer(getWinners(matches, root)) {
		return getLosers(matches, root)
	}
	matches[root+1] = rebuild(array, matches, getWinners(matches, root))
	if array[getPlayer(array, matches, getLosers(matches, root))] <
		array[getPlayer(array, matches, getWinners(matches, root))] {
		matches[root] = getPlayer(array, matches, getLosers(matches, root))
		previousLosers := getLosers(matches, root)
		matches[root+2] = getWinners(matches, root)
		matches[root+1] = previousLosers
	} else {
		matches[root] = getPlayer(array, matches, getWinners(matches, root))
	}
	return root
}

func sort(array []int) []int {
	n := len(array)
	if n <= 1 {
		return array
	}

	matches := make([]int, 6*n)
	tourney := knockout(array, matches, 0, n-1, 3)

	output := make([]int, n)
	for i := 0; i < n; i++ {
		output[i] = array[getPlayer(array, matches, tourney)]
		if isPlayer(tourney) {
			tourney = 0
		} else {
			tourney = rebuild(array, matches, tourney)
		}
	}
	return output
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
