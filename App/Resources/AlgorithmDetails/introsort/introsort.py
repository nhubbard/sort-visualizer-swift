import math


def sort(arr):
  n = len(arr)
  size_threshold = 16

  def median_of_3(left, mid, right):
    if not (arr[left] >= arr[right]):
      arr[left], arr[right] = arr[right], arr[left]
    if not (arr[left] >= arr[mid]):
      arr[left], arr[mid] = arr[mid], arr[left]
    if not (arr[mid] >= arr[right]):
      arr[mid], arr[right] = arr[right], arr[mid]
    return mid

  def partition(lo, hi, pivot_value):
    i, j = lo, hi
    while True:
      while arr[i] < pivot_value:
        i += 1
      j -= 1
      while pivot_value < arr[j]:
        j -= 1
      if not (i < j):
        return i
      arr[i], arr[j] = arr[j], arr[i]
      i += 1

  def heap_sort_range(lo, hi):
    size = hi - lo

    def sift_down(root, range_size):
      while True:
        largest = root
        left = 2 * root + 1
        right = 2 * root + 2
        if left < range_size and arr[lo + largest] < arr[lo + left]:
          largest = left
        if right < range_size and arr[lo + largest] < arr[lo + right]:
          largest = right
        if largest == root:
          break
        arr[lo + root], arr[lo + largest] = arr[lo + largest], arr[lo + root]
        root = largest

    for i in range(size // 2 - 1, -1, -1):
      sift_down(i, size)
    for end in range(size - 1, 0, -1):
      arr[lo], arr[lo + end] = arr[lo + end], arr[lo]
      sift_down(0, end)

  def introsort_loop(lo, hi, depth_limit):
    while hi - lo > size_threshold:
      if depth_limit == 0:
        heap_sort_range(lo, hi)
        return
      depth_limit -= 1
      mid = lo + (hi - lo) // 2
      pivot_index = median_of_3(lo, mid, hi - 1)
      pivot_value = arr[pivot_index]
      p = partition(lo, hi, pivot_value)
      introsort_loop(p, hi, depth_limit)
      hi = p

  def insertion_sort(start, end):
    for i in range(start + 1, end):
      j = i
      while j > start and arr[j] < arr[j - 1]:
        arr[j - 1], arr[j] = arr[j], arr[j - 1]
        j -= 1

  def floor_log2(a):
    return math.floor(math.log(a) / math.log(2))

  introsort_loop(0, n, 2 * floor_log2(n))
  insertion_sort(0, n)


if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
