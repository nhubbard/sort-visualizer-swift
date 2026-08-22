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

def partition_ternary_ll(arr, lo, hi)
  p = select_pivot(arr, lo, hi)
  arr[p], arr[hi - 1] = arr[hi - 1], arr[p]
  pivot_index = hi - 1

  i = lo
  k = hi - 1

  j = lo
  while j < k
    cmp = compare3(arr, j, pivot_index)
    if cmp == 0
      k -= 1
      arr[k], arr[j] = arr[j], arr[k]
      j -= 1
    elsif cmp < 0
      arr[i], arr[j] = arr[j], arr[i]
      i += 1
    end
    j += 1
  end

  (0...(hi - k)).each do |s|
    arr[i + s], arr[hi - 1 - s] = arr[hi - 1 - s], arr[i + s]
  end

  [i, i + (hi - k)]
end

def quicksort_ternary_ll(arr, lo, hi)
  if lo + 1 < hi
    first, second = partition_ternary_ll(arr, lo, hi)
    quicksort_ternary_ll(arr, lo, first)
    quicksort_ternary_ll(arr, second, hi)
  end
end

def sort(arr)
  quicksort_ternary_ll(arr, 0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
