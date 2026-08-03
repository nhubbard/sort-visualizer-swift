package main

import (
	"fmt"
)

type Node struct {
	value int
	left  *Node
	right *Node
	isRed bool
}

type addResult struct {
	node     *Node
	needsFix bool
}

func isRed(node *Node) bool {
	return node != nil && node.isRed
}

func singleRotateRight(node *Node) *Node {
	b := node.left
	node.left = b.right
	b.right = node
	b.isRed = false
	node.isRed = true
	return b
}

func singleRotateLeft(node *Node) *Node {
	b := node.right
	node.right = b.left
	b.left = node
	b.isRed = false
	node.isRed = true
	return b
}

func doubleRotateRight(node *Node) *Node {
	node.left = singleRotateLeft(node.left)
	return singleRotateRight(node)
}

func doubleRotateLeft(node *Node) *Node {
	node.right = singleRotateRight(node.right)
	return singleRotateLeft(node)
}

func add(node *Node, value int) addResult {
	if node == nil {
		return addResult{node: &Node{value: value, isRed: true}, needsFix: false}
	}

	if !node.isRed && isRed(node.left) && isRed(node.right) {
		node.isRed = true
		node.left.isRed = false
		node.right.isRed = false
	}

	if value < node.value {
		child := add(node.left, value)
		node.left = child.node
		if child.needsFix {
			if isRed(node.left.left) {
				return addResult{node: singleRotateRight(node), needsFix: false}
			}
			return addResult{node: doubleRotateRight(node), needsFix: false}
		}
		return addResult{node: node, needsFix: node.isRed && isRed(node.left)}
	}

	child := add(node.right, value)
	node.right = child.node
	if child.needsFix {
		if isRed(node.right.right) {
			return addResult{node: singleRotateLeft(node), needsFix: false}
		}
		return addResult{node: doubleRotateLeft(node), needsFix: false}
	}
	return addResult{node: node, needsFix: node.isRed && isRed(node.right)}
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
	n := len(arr)
	var root *Node
	for i := 0; i < n; i++ {
		inserted := add(root, arr[i])
		root = inserted.node
		root.isRed = false
	}

	result := make([]int, 0, n)
	traverse(root, &result)

	for i := 0; i < n; i++ {
		arr[i] = result[i]
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
