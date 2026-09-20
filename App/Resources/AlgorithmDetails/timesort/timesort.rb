def sort(a)
  n = a.length
  return a if n < 2
  scratch = a.dup
  buffer = scratch.dup
  merge_sort = lambda do |lo, hi|
    if hi - lo > 1
      mid = lo + (hi - lo) / 2
      merge_sort.call(lo, mid)
      merge_sort.call(mid, hi)
      left, right, dest = lo, mid, lo
      while left < mid && right < hi
        if scratch[left] <= scratch[right]
          buffer[dest] = scratch[left]
          left += 1
        else
          buffer[dest] = scratch[right]
          right += 1
        end
        dest += 1
      end
      while left < mid
        buffer[dest] = scratch[left]
        left += 1
        dest += 1
      end
      while right < hi
        buffer[dest] = scratch[right]
        right += 1
        dest += 1
      end
      (lo...hi).each { |i| scratch[i] = buffer[i] }
    end
  end
  merge_sort.call(0, n)
  n.times { |i| a[i] = scratch[i] }
  (1...n).each do |i|
    j = i
    while j > 0 && a[j - 1] > a[j]
      a[j - 1], a[j] = a[j], a[j - 1]
      j -= 1
    end
  end
  a
end
array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
puts sort(array).inspect
