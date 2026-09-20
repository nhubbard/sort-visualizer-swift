def sort(arr)
  n = arr.length
  return arr if n < 2
  scratch = Array.new(n)
  subarray_count = 1
  while subarray_count < n
    subarray_count *= 2
  end

  while subarray_count > 1
    i = 0
    while i < subarray_count
      low = n * i / subarray_count
      mid = n * (i + 1) / subarray_count
      high = n * (i + 2) / subarray_count
      merge(arr, scratch, low, mid, high)
      i += 2
    end
    subarray_count /= 2
  end
  arr
end

def merge(array, scratch, low, mid, high)
  left = low
  right = mid
  out = low
  while left < mid && right < high
    if array[left] <= array[right]
      scratch[out] = array[left]
      left += 1
    else
      scratch[out] = array[right]
      right += 1
    end
    out += 1
  end
  while left < mid
    scratch[out] = array[left]
    left += 1
    out += 1
  end
  while right < high
    scratch[out] = array[right]
    right += 1
    out += 1
  end
  (low...high).each { |i| array[i] = scratch[i] }
end


array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
