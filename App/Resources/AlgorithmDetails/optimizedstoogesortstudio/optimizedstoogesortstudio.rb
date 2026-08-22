def comp_swap(arr, a, b)
  if arr[a] > arr[b]
    arr[a], arr[b] = arr[b], arr[a]
    return true
  end
  false
end

def stooge_sort(arr, a, m, b, merge)
  return false if a >= m
  return comp_swap(arr, a, m) if b - a == 2

  l_change = false
  r_change = false

  a2 = (a + a + b) / 3
  b2 = (a + b + b + 2) / 3

  if m < b2
    l_change = stooge_sort(arr, a, m, b2, merge)
    if merge
      r_change = stooge_sort(arr, [a + b2 - m, a2].max, b2, b, true)
      stooge_sort(arr, a + b2 - m, a2, 2 * a2 - a, true) if r_change
    else
      r_change = stooge_sort(arr, a2, b2, b, false)
      stooge_sort(arr, a, a2, 2 * a2 - a, true) if r_change
    end
  else
    r_change = stooge_sort(arr, a2, m, b, merge)
    stooge_sort(arr, a, a2, a2 + b - m, true) if r_change
  end

  l_change || r_change
end

def sort(array)
  stooge_sort(array, 0, 1, array.length, false)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
