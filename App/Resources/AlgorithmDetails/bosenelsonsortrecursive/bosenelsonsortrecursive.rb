def sort(arr)
  n = arr.length

  comp_swap = lambda do |start, fin|
    arr[start], arr[fin] = arr[fin], arr[start] if arr[start] > arr[fin]
  end

  merge = lambda do |start1, len1, start2, len2|
    if len1 == 1 && len2 == 1
      comp_swap.call(start1, start2)
    elsif len1 == 1 && len2 == 2
      comp_swap.call(start1, start2 + 1)
      comp_swap.call(start1, start2)
    elsif len1 == 2 && len2 == 1
      comp_swap.call(start1, start2)
      comp_swap.call(start1 + 1, start2)
    else
      mid1 = len1 / 2
      mid2 = len1.odd? ? len2 / 2 : (len2 + 1) / 2
      merge.call(start1, mid1, start2, mid2)
      merge.call(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2)
      merge.call(start1 + mid1, len1 - mid1, start2, mid2)
    end
  end

  bose_nelson = lambda do |start, length|
    if length > 1
      mid = length / 2
      bose_nelson.call(start, mid)
      bose_nelson.call(start + mid, length - mid)
      merge.call(start, mid, start + mid, length - mid)
    end
  end

  bose_nelson.call(0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
