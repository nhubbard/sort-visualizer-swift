def sort(arr)
  n = arr.length
  return if n < 2
  scratch = arr.dup
  merge_size = 2
  while merge_size <= n
    copy_length = n
    index = 0
    while index < n
      stop = merge(arr, scratch, n, index, merge_size)
      copy_length = stop unless stop.nil?
      index += merge_size
    end
    arr[0...copy_length] = scratch[0...copy_length]
    merge_size *= 2
  end
  if merge_size / 2 != n
    stop = merge(arr, scratch, n, 0, merge_size)
    copy_length = stop.nil? ? n : stop
    arr[0...copy_length] = scratch[0...copy_length]
  end
end

def merge(array, scratch, n, index, merge_size)
  mid = index + merge_size / 2
  finish = [n, index + merge_size].min
  return index if mid >= finish
  left, right, out = index, mid, index
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
  nil
end


array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
