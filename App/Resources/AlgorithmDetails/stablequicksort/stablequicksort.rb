def stable_partition(arr, start, endpos)
  pivot_value = arr[start]
  left_list = []
  right_list = []

  (start + 1..endpos).each do |i|
    if arr[i] < pivot_value
      left_list << arr[i]
    else
      right_list << arr[i]
    end
  end

  write_index = start
  left_list.each do |v|
    arr[write_index] = v
    write_index += 1
  end
  pivot_index = write_index
  arr[write_index] = pivot_value
  write_index += 1
  right_list.each do |v|
    arr[write_index] = v
    write_index += 1
  end
  pivot_index
end

def stable_quick_sort(arr, start, endpos)
  if start < endpos
    p = stable_partition(arr, start, endpos)
    stable_quick_sort(arr, start, p - 1)
    stable_quick_sort(arr, p + 1, endpos)
  end
end

def sort(arr)
  stable_quick_sort(arr, 0, arr.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
