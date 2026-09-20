def merge(array, scratch, start, mid, finish)
  left = start
  right = mid
  out = start
  while left < mid && right < finish
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
  while right < finish
    scratch[out] = array[right]
    right += 1
    out += 1
  end
  (start...finish).each { |i| array[i] = scratch[i] }
end

def merge_sort(array, scratch, start, finish)
  return if finish - start < 2
  mid = start + (finish - start) / 2
  merge_sort(array, scratch, start, mid)
  merge_sort(array, scratch, mid, finish)
  merge(array, scratch, start, mid, finish)
end

def sort(array)
  scratch = Array.new(array.length)
  merge_sort(array, scratch, 0, array.length)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
