def slow_sort(array, i, j):
  if i >= j:
    return
  m = i + (j - i) // 2
  slow_sort(array, i, m)
  slow_sort(array, m + 1, j)
  if array[m] > array[j]:
    array[m], array[j] = array[j], array[m]
  slow_sort(array, i, j - 1)

def sort(arr):
  slow_sort(arr, 0, len(arr) - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
