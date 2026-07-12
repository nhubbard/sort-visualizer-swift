def multi_swap(array, a, b, length):
  for i in range(length):
    array[a + i], array[b + i] = array[b + i], array[a + i]

def rotate(array, a, m, b):
  l, r = m - a, b - m
  while l > 0 and r > 0:
    if r < l:
      multi_swap(array, m - r, m, r)
      b -= r
      m -= r
      l -= r
    else:
      multi_swap(array, a, m, l)
      a += l
      m += l
      r -= l

def binary_search(array, a, b, value, left):
  while a < b:
    mid = a + (b - a) // 2
    comp = value <= array[mid] if left else value < array[mid]
    if comp:
      b = mid
    else:
      a = mid + 1
  return a

def rotate_merge(array, a, m, b):
  if m - a >= b - m:
    m1 = a + (m - a) // 2
    value = array[m1]
    m2 = binary_search(array, m, b, value, True)
    m3 = m1 + (m2 - m)
  else:
    m2 = m + (b - m) // 2
    value = array[m2]
    m1 = binary_search(array, a, m, value, False)
    m3 = m2 - (m - m1)
    m2 = m2 + 1
  rotate(array, m1, m, m2)
  if m2 - (m3 + 1) > 0 and b - m2 > 0:
    rotate_merge(array, m3 + 1, m2, b)
  if m1 - a > 0 and m3 - m1 > 0:
    rotate_merge(array, a, m1, m3)

def rotate_merge_sort(array, a, b):
  length = b - a
  j = 1
  while j < length:
    i = a
    while i + 2 * j <= b:
      rotate_merge(array, i, i + j, i + 2 * j)
      i += 2 * j
    if i + j < b:
      rotate_merge(array, i, i + j, b)
    j *= 2

def sort(arr):
  rotate_merge_sort(arr, 0, len(arr))

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
