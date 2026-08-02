def comp_swap(arr, a, b, sort_end)
  if b < sort_end && arr[a] > arr[b]
    arr[a], arr[b] = arr[b], arr[a]
  end
end

def halver(arr, low, high, sort_end)
  while low < high
    comp_swap(arr, low, high, sort_end)
    low += 1
    high -= 1
  end
end

def sort(arr)
  n = arr.length
  ceil_log = 1
  while (1 << ceil_log) < n
    ceil_log += 1
  end
  sort_end = n
  size2 = 1 << ceil_log

  k = size2 >> 1
  while k > 0
    i = size2
    while i >= k
      j = 0
      while j < sort_end
        halver(arr, j, j + i - 1, sort_end)
        j += i
      end
      i >>= 1
    end
    k >>= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
