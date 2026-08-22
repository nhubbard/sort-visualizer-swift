package main

import (
	"fmt"
)

type Node struct {
	value   int
	left    *Node
	right   *Node
	balance int
}

type addResult struct {
	node          *Node
	heightChanged bool
}

func singleRotateRight(node *Node) *Node {
	b := node.left
	node.left = b.right
	b.right = node
	node.balance = 0
	b.balance = 0
	return b
}

func singleRotateLeft(node *Node) *Node {
	b := node.right
	node.right = b.left
	b.left = node
	node.balance = 0
	b.balance = 0
	return b
}

func doubleRotateRight(node *Node) *Node {
	oldBBalance := node.left.right.balance
	node.left = singleRotateLeft(node.left)
	b := singleRotateRight(node)
	if oldBBalance == -1 {
		b.right.balance = 1
	}
	if oldBBalance == 1 {
		b.left.balance = -1
	}
	return b
}

func doubleRotateLeft(node *Node) *Node {
	oldBBalance := node.right.left.balance
	node.right = singleRotateRight(node.right)
	b := singleRotateLeft(node)
	if oldBBalance == -1 {
		b.right.balance = 1
	}
	if oldBBalance == 1 {
		b.left.balance = -1
	}
	return b
}

func heightChangeLeft(node *Node) addResult {
	if node.balance != -1 {
		node.balance--
		return addResult{node, node.balance == -1}
	}
	if node.left.balance == -1 {
		return addResult{singleRotateRight(node), false}
	}
	return addResult{doubleRotateRight(node), false}
}

func heightChangeRight(node *Node) addResult {
	if node.balance != 1 {
		node.balance++
		return addResult{node, node.balance == 1}
	}
	if node.right.balance == 1 {
		return addResult{singleRotateLeft(node), false}
	}
	return addResult{doubleRotateLeft(node), false}
}

func add(node *Node, value int) addResult {
	if node == nil {
		return addResult{&Node{value: value}, true}
	}
	if value < node.value {
		result := add(node.left, value)
		node.left = result.node
		if result.heightChanged {
			return heightChangeLeft(node)
		}
		return addResult{node, false}
	}
	result := add(node.right, value)
	node.right = result.node
	if result.heightChanged {
		return heightChangeRight(node)
	}
	return addResult{node, false}
}

func traverse(node *Node, result *[]int) {
	if node == nil {
		return
	}
	traverse(node.left, result)
	*result = append(*result, node.value)
	traverse(node.right, result)
}

func sort(arr []int) []int {
	var root *Node
	for _, value := range arr {
		root = add(root, value).node
	}

	result := make([]int, 0, len(arr))
	traverse(root, &result)

	for i := range arr {
		arr[i] = result[i]
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
