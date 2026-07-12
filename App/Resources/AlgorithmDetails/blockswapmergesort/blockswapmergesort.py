def multi_swap(array, a, b, length):
  for i in range(length):
    array[a + i], array[b + i] = array[b + i], array[a + i]

def binary_search_mid(array, start, mid, end):
  a = 0
  b = min(mid - start, end - mid)
  m = a + (b - a) // 2
  while b > a:
    if array[mid - m - 1] > array[mid + m]:
      a = m + 1
    else:
      b = m
    m = a + (b - a) // 2
  return m

def multi_swap_merge(array, start, mid, end):
  m = binary_search_mid(array, start, mid, end)
  while m > 0:
    multi_swap(array, mid - m, mid, m)
    multi_swap_merge(array, mid, mid + m, end)
    end = mid
    mid -= m
    m = binary_search_mid(array, start, mid, end)

def multi_swap_merge_sort(array, a, b):
  length = b - a
  j = 1
  while j < length:
    i = a
    while i + 2 * j <= b:
      multi_swap_merge(array, i, i + j, i + 2 * j)
      i += 2 * j
    if i + j < b:
      multi_swap_merge(array, i, i + j, b)
    j *= 2

def sort(array):
  multi_swap_merge_sort(array, 0, len(array))
  return array

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
