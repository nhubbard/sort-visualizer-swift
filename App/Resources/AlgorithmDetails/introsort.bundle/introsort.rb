def sort(arr)
  n = arr.length()
  size_threshold = 16

  median_of_3 = lambda do |left, mid, right|
    unless arr[left] >= arr[right]
      arr[left], arr[right] = arr[right], arr[left]
    end
    unless arr[left] >= arr[mid]
      arr[left], arr[mid] = arr[mid], arr[left]
    end
    unless arr[mid] >= arr[right]
      arr[mid], arr[right] = arr[right], arr[mid]
    end
    mid
  end

  partition = lambda do |lo, hi, pivot_value|
    i = lo
    j = hi
    loop do
      while arr[i] < pivot_value
        i += 1
      end
      j -= 1
      while pivot_value < arr[j]
        j -= 1
      end
      break i unless i < j
      arr[i], arr[j] = arr[j], arr[i]
      i += 1
    end
  end

  sift_down = lambda do |lo, root, range_size|
    r = root
    loop do
      largest = r
      left = 2 * r + 1
      right = 2 * r + 2
      largest = left if left < range_size && arr[lo + largest] < arr[lo + left]
      largest = right if right < range_size && arr[lo + largest] < arr[lo + right]
      break if largest == r
      arr[lo + r], arr[lo + largest] = arr[lo + largest], arr[lo + r]
      r = largest
    end
  end

  heap_sort_range = lambda do |lo, hi|
    size = hi - lo
    (size / 2 - 1).downto(0) { |i| sift_down.call(lo, i, size) }
    (size - 1).downto(1) do |e|
      arr[lo], arr[lo + e] = arr[lo + e], arr[lo]
      sift_down.call(lo, 0, e)
    end
  end

  insertion_sort = lambda do |start, fin|
    (start + 1...fin).each do |i|
      j = i
      while j > start && arr[j] < arr[j - 1]
        arr[j - 1], arr[j] = arr[j], arr[j - 1]
        j -= 1
      end
    end
  end

  floor_log2 = lambda do |a|
    Math.log2(a).floor
  end

  introsort_loop = lambda do |lo, hi, depth_limit|
    h = hi
    d = depth_limit
    while h - lo > size_threshold
      if d == 0
        heap_sort_range.call(lo, h)
        return
      end
      d -= 1
      mid = lo + (h - lo) / 2
      pivot_index = median_of_3.call(lo, mid, h - 1)
      pivot_value = arr[pivot_index]
      split_point = partition.call(lo, h, pivot_value)
      introsort_loop.call(split_point, h, d)
      h = split_point
    end
  end

  introsort_loop.call(0, n, 2 * floor_log2.call(n))
  insertion_sort.call(0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
