def partition(array, start, end):
  pivot = array[start]
  low = start + 1
  high = end
  while True:
    while low <= high and array[high] >= pivot:
      high = high - 1
    while low <= high and array[low] <= pivot:
      low = low + 1
    if low <= high:
      array[low], array[high] = array[high], array[low]
    else:
      break
  array[start], array[high] = array[high], array[start]
  return high

def quick_sort(array, start, end):
  if start >= end:
    return
  p = partition(array, start, end)
  quick_sort(array, start, p - 1)
  quick_sort(array, p + 1, end)

def sort(arr):
  quick_sort(arr, 0, len(arr) - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)