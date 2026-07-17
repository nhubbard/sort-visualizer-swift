package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)

	height := func(node int) int {
		count := 0
		for (node>>count)%2 == 1 {
			count += 1
		}
		return count
	}

	var thrift func(node int, parentFlag bool, rootFlag bool)
	thrift = func(node int, parentFlag bool, rootFlag bool) {
		isRoot := rootFlag && (node >= (1 << height(node)))
		if !isRoot && !parentFlag {
			return
		}

		choice := height(node)
		if !isRoot {
			choice -= 1
		}
		if parentFlag {
			for child := choice - 1; child >= 0; child-- {
				if arr[node-(1<<choice)] <= arr[node-(1<<child)] {
					choice = child
				}
			}
		}

		if arr[node-(1<<choice)] <= arr[node] {
			return
		}

		arr[node], arr[node-(1<<choice)] = arr[node-(1<<choice)], arr[node]
		nextNode := node - (1 << choice)
		thrift(nextNode, nextNode%2 == 1, choice == height(node))
	}

	node := 1
	for node < n {
		thrift(node, node%2 == 1, (node+(1<<height(node))) >= n)
		node += 1
	}

	node -= (node - 1) % 2
	for node > 2 {
		for child := height(node) - 1; child >= 0; child-- {
			thrift(node-(1<<child), false, true)
		}
		node -= 2
	}

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
