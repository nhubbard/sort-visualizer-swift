package main

import "fmt"

func ceilPow2(value int) int {
	r := 1
	for r < value {
		r *= 2
	}
	return r
}

func sort(array []int) {
	n := len(array)
	if n <= 1 {
		return
	}

	size := ceilPow2(n) - 1
	mod := n % 2
	treeSize := n + size + mod
	tree := make([]int, treeSize)
	for i := range tree {
		tree[i] = -1
	}

	treeCompare := func(a, b int) bool {
		return array[tree[a]] <= array[tree[b]]
	}

	for i := size; i < treeSize-mod; i++ {
		tree[i] = i - size
	}

	j := size
	k := treeSize - mod
	for j > 0 {
		i := j
		for i+1 < k {
			if treeCompare(i, i+1) {
				tree[i/2] = tree[i]
			} else {
				tree[i/2] = tree[i+1]
			}
			i += 2
		}
		if i < k {
			tree[i/2] = tree[i]
		}
		j /= 2
		k /= 2
	}

	findNext := func() int {
		path := tree[0] + size
		for path > 0 {
			tree[path] = -1
			path = (path - 1) / 2
		}

		node := tree[0] + size
		for node > 0 {
			sibling := node - 1
			if node%2 == 1 {
				sibling = node + 1
			}
			nodeValid := tree[node] != -1
			siblingValid := tree[sibling] != -1
			winner := -1
			if nodeValid && siblingValid {
				if node < sibling {
					if treeCompare(node, sibling) {
						winner = tree[node]
					} else {
						winner = tree[sibling]
					}
				} else {
					if treeCompare(sibling, node) {
						winner = tree[sibling]
					} else {
						winner = tree[node]
					}
				}
			} else if nodeValid {
				winner = tree[node]
			} else if siblingValid {
				winner = tree[sibling]
			}
			node = (node - 1) / 2
			if winner != -1 {
				tree[node] = winner
			}
		}
		return array[tree[0]]
	}

	output := make([]int, n)
	output[0] = array[tree[0]]
	for i := 1; i < n; i++ {
		output[i] = findNext()
	}
	copy(array, output)
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	sort(array)
	fmt.Println(array)
}
