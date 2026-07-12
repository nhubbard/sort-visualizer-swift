def binary_search(array, item, start, end):
  low = start
  high = end
  while low < high:
    mid = low + (high - low) // 2
    if item < array[mid]:
      high = mid
    else:
      low = mid + 1
  return low

def binary_insertion_sort(array):
  for i in range(1, len(array)):
    item = array[i]
    pos = binary_search(array, item, 0, i)
    j = i
    while j > pos:
      array[j] = array[j - 1]
      j -= 1
    array[pos] = item

def sort(arr):
  binary_insertion_sort(arr)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
