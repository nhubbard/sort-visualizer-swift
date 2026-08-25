package main

import (
	"fmt"
)

// elem tags a value with its original index so a pending element can find its way back to the
// right chain partner even after the chain has been recursively reordered.
type elem struct {
	value int
	index int
}

// binaryInsert inserts e into the already-sorted seq via binary search, comparing by value only.
func binaryInsert(seq []elem, e elem) []elem {
	lo, hi := 0, len(seq)
	for lo < hi {
		mid := (lo + hi) / 2
		if seq[mid].value <= e.value {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	seq = append(seq, elem{})
	copy(seq[lo+1:], seq[lo:len(seq)-1])
	seq[lo] = e
	return seq
}

// jacobsthalT returns the k-th term of the sequence t(k) = (2^(k+1) + (-1)^k) / 3.
func jacobsthalT(k int) int {
	sign := 1
	if k%2 != 0 {
		sign = -1
	}
	return ((1 << (k + 1)) + sign) / 3
}

// jacobsthalInsertionOrder returns, as 1-based positions into a list of count not-yet-placed
// pending elements, the order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20
// down to 11, and so on. This Jacobsthal-number grouping is what makes merge-insertion sort
// comparison-optimal. Position 1 is never included -- it is always placed for free before any
// of these insertions happen.
func jacobsthalInsertionOrder(count int) []int {
	maxPosition := count + 1
	order := []int{}
	placedThrough := 1
	k := 2
	for placedThrough < maxPosition {
		groupEnd := jacobsthalT(k) - 1
		if groupEnd > maxPosition {
			groupEnd = maxPosition
		}
		for position := groupEnd; position > placedThrough; position-- {
			order = append(order, position)
		}
		placedThrough = groupEnd
		k++
	}
	return order
}

// pairUp splits items into chain (the larger element of each adjacent pair), partnerOf (mapping
// a chain element's original index to its paired, smaller element), and extra (a leftover
// element with no partner when items has odd length).
func pairUp(items []elem) ([]elem, map[int]elem, *elem) {
	chain := []elem{}
	partnerOf := map[int]elem{}
	i := 0
	n := len(items)
	for i+1 < n {
		a, b := items[i], items[i+1]
		small, large := a, b
		if a.value > b.value {
			small, large = b, a
		}
		partnerOf[large.index] = small
		chain = append(chain, large)
		i += 2
	}
	var extra *elem
	if i < n {
		leftover := items[i]
		extra = &leftover
	}
	return chain, partnerOf, extra
}

// sortTagged sorts a list of elem by value. The index tags are what let a pending element find
// its way back to the right chain partner after the chain has been recursively reordered by
// this same function one level down.
func sortTagged(items []elem) []elem {
	if len(items) <= 1 {
		return append([]elem{}, items...)
	}

	chain, partnerOf, extra := pairUp(items)
	sortedChain := sortTagged(chain)

	// The pending partner of the smallest chain element is guaranteed smaller than every
	// other chain element too, so it can go straight to the front with no comparison at all.
	sequence := make([]elem, 0, len(items))
	sequence = append(sequence, partnerOf[sortedChain[0].index])
	sequence = append(sequence, sortedChain...)

	remaining := []elem{}
	for k := 1; k < len(sortedChain); k++ {
		remaining = append(remaining, partnerOf[sortedChain[k].index])
	}
	if extra != nil {
		remaining = append(remaining, *extra)
	}

	for _, position := range jacobsthalInsertionOrder(len(remaining)) {
		sequence = binaryInsert(sequence, remaining[position-2])
	}

	return sequence
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	tagged := make([]elem, n)
	for i, v := range arr {
		tagged[i] = elem{value: v, index: i}
	}
	sortedTagged := sortTagged(tagged)
	for i, e := range sortedTagged {
		arr[i] = e.value
	}
	return arr
}

func main() {
	array := []int{34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60}
	fmt.Println(sort(array))
}
