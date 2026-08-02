def comp_swap(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a] if arr[a] > arr[b]
end

def sort(arr)
  length = arr.length
  max_val = 1
  max_val *= 2 while max_val * 2 < length

  nxt = max_val
  while nxt > 0
    i = 0
    while i + 1 < length
      comp_swap(arr, i, i + 1)
      i += 2
    end

    j = max_val
    while j >= nxt && j > 1
      i = 1
      while i + j - 1 < length
        comp_swap(arr, i, i + j - 1)
        i += 2
      end
      j /= 2
    end

    nxt /= 2
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
