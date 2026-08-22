package main

import (
	"fmt"
)

type Node struct {
	value int
	level int
	left  *Node
	right *Node
}

func newNode(value int) *Node {
	return &Node{value: value, level: 0}
}

func nodeLevel(node *Node) int {
	if node == nil {
		return -1
	}
	return node.level
}

func skew(node *Node) *Node {
	if node.left == nil {
		return node
	}
	l := node.left
	node.left = l.right
	l.right = node
	return l
}

func split(node *Node) *Node {
	if node.right == nil {
		return node
	}
	r := node.right
	node.right = r.left
	r.left = node
	r.level++
	return r
}

func add(node *Node, value int) *Node {
	if node == nil {
		return newNode(value)
	}
	if value < node.value {
		node.left = add(node.left, value)
		if nodeLevel(node.left) == node.level {
			if node.level != nodeLevel(node.right) {
				return skew(node)
			}
			node.level++
			return node
		}
		return node
	}
	node.right = add(node.right, value)
	if nodeLevel(node.right.right) == node.level {
		return split(node)
	}
	return node
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
		root = add(root, arr[i])
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
