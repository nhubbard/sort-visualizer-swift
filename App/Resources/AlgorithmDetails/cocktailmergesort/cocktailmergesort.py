def min_run_length(n):
  r = 0
  while n >= 64:
    r |= n & 1
    n >>= 1
  return n + r

def cocktail_shaker_sort(array, start, end):
  length = end - start
  if length <= 1:
    return
  i = 0
  while i < length // 2:
    is_sorted = True
    j = i
    while j < length - i - 1:
      if array[start + j] > array[start + j + 1]:
        array[start + j], array[start + j + 1] = array[start + j + 1], array[start + j]
        is_sorted = False
      j += 1
    j = length - i - 1
    while j > i:
      if array[start + j - 1] > array[start + j]:
        array[start + j - 1], array[start + j] = array[start + j], array[start + j - 1]
        is_sorted = False
      j -= 1
    if is_sorted:
      break
    i += 1

def merge(array, start, mid, end):
  left = array[start:mid]
  right = array[mid:end]
  i = j = 0
  k = start
  while i < len(left) and j < len(right):
    if left[i] <= right[j]:
      array[k] = left[i]
      i += 1
    else:
      array[k] = right[j]
      j += 1
    k += 1
  while i < len(left):
    array[k] = left[i]
    i += 1
    k += 1
  while j < len(right):
    array[k] = right[j]
    j += 1
    k += 1

def cocktail_merge_sort(array):
  n = len(array)
  if n <= 1:
    return
  min_run = min_run_length(n)
  if n == min_run:
    cocktail_shaker_sort(array, 0, n)
    return
  i = 0
  while i <= n - min_run:
    cocktail_shaker_sort(array, i, i + min_run)
    i += min_run
  if i < n:
    cocktail_shaker_sort(array, i, n)
  width = min_run
  while width < n:
    i = 0
    while i < n:
      mid = min(i + width, n)
      end = min(i + 2 * width, n)
      if mid < end:
        merge(array, i, mid, end)
      i += 2 * width
    width *= 2

def sort(arr):
  cocktail_merge_sort(arr)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
