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
  quick_sort(array, start, p-1)
  quick_sort(array, p+1, end)

if __name__ == "__main__":
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  quick_sort(array, 0, len(array) - 1)
  print(array)
