def sort(arr)
  scratch = Array.new(arr.length, 0)
  merge_sort = lambda do |start, finish|
    if finish - start > 1
      middle = (start + finish) / 2
      merge_sort.call(start, middle)
      merge_sort.call(middle, finish)
      left = start
      right = middle
      dest = start
      while left < middle && right < finish
        if arr[left] <= arr[right]
          scratch[dest] = arr[left]
          left += 1
        else
          scratch[dest] = arr[right]
          right += 1
        end
        dest += 1
      end
      while left < middle
        scratch[dest] = arr[left]
        left += 1
        dest += 1
      end
      while right < finish
        scratch[dest] = arr[right]
        right += 1
        dest += 1
      end
      (start...finish).each { |i| arr[i] = scratch[i] }
    end
  end

  start = 0
  finish = arr.length
  while finish - start > 16
    pivot = [arr[start], arr[(start + finish - 1) / 2], arr[finish - 1]].sort[1]
    left = start
    right = finish - 1
    while left <= right
      left += 1 while left <= right && arr[left] < pivot
      right -= 1 while left <= right && arr[right] > pivot
      if left <= right
        arr[left], arr[right] = arr[right], arr[left]
        left += 1
        right -= 1
      end
    end
    if left == start || left == finish
      merge_sort.call(start, finish)
      return
    end
    if left - start <= finish - left
      merge_sort.call(start, left)
      start = left
    else
      merge_sort.call(left, finish)
      finish = left
    end
  end

  (start + 1...finish).each do |i|
    value = arr[i]
    j = i
    while j > start && arr[j - 1] > value
      arr[j] = arr[j - 1]
      j -= 1
    end
    arr[j] = value
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
  10, 2, 95, 46, 21, 74, 6, 38]
sort(array)
p array
