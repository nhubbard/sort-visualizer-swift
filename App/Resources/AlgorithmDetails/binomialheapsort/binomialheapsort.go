package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)

  index := 2
  for index <= n {
    maxNode := index
    for {
      focus := maxNode
      depth := 1
      for (focus & depth) == 0 {
        if arr[focus - depth - 1] > arr[maxNode - 1] {
          maxNode = focus - depth
        }
        depth *= 2
      }
      if focus != maxNode {
        arr[focus - 1], arr[maxNode - 1] = arr[maxNode - 1], arr[focus - 1]
      }
      if focus == maxNode {
        break
      }
    }
    index += 2
  }

  index = n
  for index > 2 {
    maxNode := index
    focus := index
    depth := 1
    for focus != 0 {
      if (focus & depth) != 0 {
        if arr[focus - 1] > arr[maxNode - 1] {
          maxNode = focus
        }
        focus -= depth
      }
      depth *= 2
    }

    if maxNode != index {
      focus = index
      for {
        arr[focus - 1], arr[maxNode - 1] = arr[maxNode - 1], arr[focus - 1]
        focus = maxNode
        innerDepth := 1
        for (focus & innerDepth) == 0 {
          if arr[focus - innerDepth - 1] > arr[maxNode - 1] {
            maxNode = focus - innerDepth
          }
          innerDepth *= 2
        }
        if focus == maxNode {
          break
        }
      }
    }
    index -= 1
  }

  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
