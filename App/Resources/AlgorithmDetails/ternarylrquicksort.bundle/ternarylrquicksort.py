def compare3(arr, a, b):
  if arr[a] == arr[b]:
    return 0
  return 1 if arr[a] > arr[b] else -1

def select_pivot(arr, lo, hi):
  mid = (lo + hi) // 2
  c_lo_mid = compare3(arr, lo, mid)
  if c_lo_mid == 0:
    return lo
  c_lo_hi = compare3(arr, lo, hi - 1)
  c_mid_hi = compare3(arr, mid, hi - 1)
  if c_lo_hi == 0 or c_mid_hi == 0:
    return hi - 1

  if c_lo_mid < 0:
    return mid if c_mid_hi < 0 else (hi - 1 if c_lo_hi < 0 else lo)
  else:
    return mid if c_mid_hi > 0 else (lo if c_lo_hi < 0 else hi - 1)

def quicksort_ternary_lr(arr, lo, hi):
  if hi <= lo:
    return

  piv = select_pivot(arr, lo, hi + 1)
  arr[piv], arr[hi] = arr[hi], arr[piv]
  pivot_index = hi

  i, j = lo, hi - 1
  p, q = lo, hi - 1

  while True:
    while i <= j and (cmp := compare3(arr, i, pivot_index)) <= 0:
      if cmp == 0:
        arr[i], arr[p] = arr[p], arr[i]
        p += 1
      i += 1
    while i <= j and (cmp := compare3(arr, j, pivot_index)) >= 0:
      if cmp == 0:
        arr[j], arr[q] = arr[q], arr[j]
        q -= 1
      j -= 1
    if i > j:
      break
    arr[i], arr[j] = arr[j], arr[i]
    i += 1
    j -= 1

  arr[i], arr[hi] = arr[hi], arr[i]

  num_less = i - p
  num_greater = q - j

  j = i - 1
  i = i + 1

  pe = lo + min(p - lo, num_less)
  k = lo
  while k < pe:
    arr[k], arr[j] = arr[j], arr[k]
    k += 1
    j -= 1

  qe = hi - 1 - min(hi - 1 - q, num_greater - 1)
  k = hi - 1
  while k > qe:
    arr[i], arr[k] = arr[k], arr[i]
    k -= 1
    i += 1

  quicksort_ternary_lr(arr, lo, lo + num_less - 1)
  quicksort_ternary_lr(arr, hi - num_greater + 1, hi)

def sort(arr):
  quicksort_ternary_lr(arr, 0, len(arr) - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
