package main

import (
	"fmt"
)

type Node struct {
	pointer int
	left    *Node
	right   *Node
}

func add(arr []int, node *Node, addPtr int) *Node {
	if node == nil {
		return &Node{pointer: addPtr}
	}
	if arr[addPtr] < arr[node.pointer] {
		node.left = add(arr, node.left, addPtr)
	} else {
		node.right = add(arr, node.right, addPtr)
	}
	return node
}

func traverse(arr []int, node *Node, result *[]int) {
	if node == nil {
		return
	}
	traverse(arr, node.left, result)
	*result = append(*result, arr[node.pointer])
	traverse(arr, node.right, result)
}

func sort(arr []int) []int {
	n := len(arr)
	var root *Node
	for i := 0; i < n; i++ {
		root = add(arr, root, i)
	}

	result := make([]int, 0, n)
	traverse(arr, root, &result)

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
