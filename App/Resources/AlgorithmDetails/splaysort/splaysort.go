package main

import (
	"fmt"
)

type Node struct {
	key   int
	left  *Node
	right *Node
}

func leftRotate(x *Node) *Node {
	y := x.right
	x.right = y.left
	y.left = x
	return y
}

func rightRotate(x *Node) *Node {
	y := x.left
	x.left = y.right
	y.right = x
	return y
}

func splay(root *Node, key int) *Node {
	if root == nil {
		return root
	}
	if root.key > key {
		if root.left == nil {
			return root
		}
		if root.left.key > key {
			root.left.left = splay(root.left.left, key)
			root = rightRotate(root)
		} else {
			root.left.right = splay(root.left.right, key)
			if root.left.right != nil {
				root.left = leftRotate(root.left)
			}
		}
		if root.left == nil {
			return root
		}
		return rightRotate(root)
	} else {
		if root.right == nil {
			return root
		}
		if root.right.key > key {
			root.right.left = splay(root.right.left, key)
			if root.right.left != nil {
				root.right = rightRotate(root.right)
			}
		} else {
			root.right.right = splay(root.right.right, key)
			root = leftRotate(root)
		}
		if root.right == nil {
			return root
		}
		return leftRotate(root)
	}
}

func insertRec(root *Node, key int) *Node {
	if root == nil {
		return &Node{key: key}
	}
	root = splay(root, key)
	n := &Node{key: key}
	if root.key > key {
		n.right = root
		n.left = root.left
		root.left = nil
	} else {
		n.left = root
		n.right = root.right
		root.right = nil
	}
	return n
}

func traverse(node *Node, result []int, idx *int) {
	if node != nil {
		traverse(node.left, result, idx)
		result[*idx] = node.key
		*idx++
		traverse(node.right, result, idx)
	}
}

func sort(arr []int) []int {
	var root *Node
	for _, x := range arr {
		root = insertRec(root, x)
	}
	result := make([]int, len(arr))
	idx := 0
	traverse(root, result, &idx)
	copy(arr, result)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
