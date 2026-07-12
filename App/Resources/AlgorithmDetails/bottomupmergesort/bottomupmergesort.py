def merge(array, low, mid, high):
  left = array[low:mid]
  right = array[mid:high]
  i = j = 0
  k = low
  while i < len(left) and j < len(right):
    if left[i] <= right[j]:
      array[k] = left[i]
      i = i + 1
    else:
      array[k] = right[j]
      j = j + 1
    k = k + 1
  while i < len(left):
    array[k] = left[i]
    i = i + 1
    k = k + 1
  while j < len(right):
    array[k] = right[j]
    j = j + 1
    k = k + 1

def sort(arr):
  n = len(arr)
  width = 1
  while width < n:
    low = 0
    while low < n:
      mid = min(low + width, n)
      high = min(low + 2 * width, n)
      if mid < high:
        merge(arr, low, mid, high)
      low = low + 2 * width
    width = width * 2

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
