def greatest_power_of_two_less_than(n):
  k = 1
  while k < n:
    k <<= 1
  return k >> 1

def compare(array, i, j, dir):
  is_greater = array[i] > array[j]
  if dir == is_greater:
    array[i], array[j] = array[j], array[i]

def bitonic_merge(array, lo, n, dir):
  if n > 1:
    m = greatest_power_of_two_less_than(n)
    for i in range(lo, lo + n - m):
      compare(array, i, i + m, dir)
    bitonic_merge(array, lo, m, dir)
    bitonic_merge(array, lo + m, n - m, dir)

def bitonic_sort(array, lo, n, dir):
  if n > 1:
    m = n // 2
    bitonic_sort(array, lo, m, not dir)
    bitonic_sort(array, lo + m, n - m, dir)
    bitonic_merge(array, lo, n, dir)

def sort(arr):
  bitonic_sort(arr, 0, len(arr), True)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
