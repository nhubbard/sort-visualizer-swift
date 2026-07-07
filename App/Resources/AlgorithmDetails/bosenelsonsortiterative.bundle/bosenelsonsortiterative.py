def comp_swap(array, a, b, end):
  if b >= end:
    return
  if array[a] > array[b]:
    array[a], array[b] = array[b], array[a]

def range_comp(array, a, b, offset, end):
  half = (b - a) // 2
  m = a + half
  base = a + offset
  i = 0
  while i < half - offset:
    if (i & ~offset) == i:
      comp_swap(array, base + i, m + i, end)
    i += 1

def sort(arr):
  end = len(arr)
  if end <= 1:
    return
  padded_length = 1
  while padded_length < end:
    padded_length <<= 1

  k = 2
  while k <= padded_length:
    j = 0
    while j < k // 2:
      i = 0
      while i + j < end:
        range_comp(arr, i, i + k, j, end)
        i += k
      j += 1
    k *= 2

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
