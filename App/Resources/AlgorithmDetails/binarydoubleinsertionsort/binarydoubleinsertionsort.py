def left_binary_search(array, a, b, val):
  lo, hi = a, b
  while lo < hi:
    mid = lo + (hi - lo) // 2
    if val <= array[mid]:
      hi = mid
    else:
      lo = mid + 1
  return lo

def right_binary_search(array, a, b, val):
  lo, hi = a, b
  while lo < hi:
    mid = lo + (hi - lo) // 2
    if val < array[mid]:
      hi = mid
    else:
      lo = mid + 1
  return lo

def insert_to_left(array, a, b, temp):
  while a > b:
    array[a] = array[a - 1]
    a -= 1
  array[b] = temp

def insert_to_right(array, a, b, temp):
  while a < b:
    array[a] = array[a + 1]
    a += 1
  array[a] = temp

def double_insertion(array, a, b):
  if b - a < 2:
    return

  j = a + (b - a - 2) // 2 + 1
  i = a + (b - a - 1) // 2

  if j > i and array[i] > array[j]:
    array[i], array[j] = array[j], array[i]
  i -= 1
  j += 1

  while j < b:
    if array[i] > array[j]:
      l = array[j]
      r = array[i]
      m = right_binary_search(array, i + 1, j, l)
      insert_to_right(array, i, m - 1, l)
      dest = left_binary_search(array, m, j, r)
      insert_to_left(array, j, dest, r)
    else:
      l = array[i]
      r = array[j]
      m = left_binary_search(array, i + 1, j, l)
      insert_to_right(array, i, m - 1, l)
      dest = right_binary_search(array, m, j, r)
      insert_to_left(array, j, dest, r)
    i -= 1
    j += 1

def sort(arr):
  if len(arr) > 1:
    double_insertion(arr, 0, len(arr))

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
