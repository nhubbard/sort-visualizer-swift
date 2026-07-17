def compare3(arr, a, b)
  return 0 if arr[a] == arr[b]
  (arr[a] > arr[b]) ? 1 : -1
end

def select_pivot(arr, lo, hi)
  mid = (lo + hi) / 2
  c_lo_mid = compare3(arr, lo, mid)
  return lo if c_lo_mid == 0
  c_lo_hi = compare3(arr, lo, hi - 1)
  c_mid_hi = compare3(arr, mid, hi - 1)
  return hi - 1 if c_lo_hi == 0 || c_mid_hi == 0

  if c_lo_mid < 0
    if c_mid_hi < 0
      mid
    else
      ((c_lo_hi < 0) ? hi - 1 : lo)
    end
  elsif c_mid_hi > 0
    mid
  else
    ((c_lo_hi < 0) ? lo : hi - 1)
  end
end

def quicksort_ternary_lr(arr, lo, hi)
  return if hi <= lo

  piv = select_pivot(arr, lo, hi + 1)
  arr[piv], arr[hi] = arr[hi], arr[piv]
  pivot_index = hi

  i = lo
  j = hi - 1
  p = lo
  q = hi - 1

  loop do
    cmp = nil
    while i <= j && (cmp = compare3(arr, i, pivot_index)) <= 0
      if cmp == 0
        arr[i], arr[p] = arr[p], arr[i]
        p += 1
      end
      i += 1
    end
    while i <= j && (cmp = compare3(arr, j, pivot_index)) >= 0
      if cmp == 0
        arr[j], arr[q] = arr[q], arr[j]
        q -= 1
      end
      j -= 1
    end
    break if i > j
    arr[i], arr[j] = arr[j], arr[i]
    i += 1
    j -= 1
  end

  arr[i], arr[hi] = arr[hi], arr[i]

  num_less = i - p
  num_greater = q - j

  j = i - 1
  i += 1

  pe = lo + [p - lo, num_less].min
  k = lo
  while k < pe
    arr[k], arr[j] = arr[j], arr[k]
    k += 1
    j -= 1
  end

  qe = hi - 1 - [hi - 1 - q, num_greater - 1].min
  k = hi - 1
  while k > qe
    arr[i], arr[k] = arr[k], arr[i]
    k -= 1
    i += 1
  end

  quicksort_ternary_lr(arr, lo, lo + num_less - 1)
  quicksort_ternary_lr(arr, hi - num_greater + 1, hi)
end

def sort(arr)
  quicksort_ternary_lr(arr, 0, arr.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
