def push(array, low, high):
  for i in range(low, high):
    if array[i] > array[i + 1]:
      array[i], array[i + 1] = array[i + 1], array[i]

def merge(array, low, high, mid):
  i = low
  while i <= mid:
    if array[i] > array[mid + 1]:
      array[i], array[mid + 1] = array[mid + 1], array[i]
      push(array, mid + 1, high)
    i += 1

def merge_sort(array, low, high):
  if high - low == 0:
    return
  elif high - low == 1:
    if array[low] > array[high]:
      array[low], array[high] = array[high], array[low]
  else:
    mid = (low + high) // 2
    merge_sort(array, low, mid)
    merge_sort(array, mid + 1, high)
    merge(array, low, high, mid)

def sort(arr):
  if len(arr) >= 2:
    merge_sort(arr, 0, len(arr) - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
