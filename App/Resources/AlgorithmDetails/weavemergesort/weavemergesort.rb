def multi_swap(arr, pos, to)
  if to - pos > 0
    (pos...to).each do |i|
      arr[i], arr[i + 1] = arr[i + 1], arr[i]
    end
  else
    pos.downto(to + 1) do |i|
      arr[i], arr[i - 1] = arr[i - 1], arr[i]
    end
  end
end

def weave_insert(arr, start, en)
  (start...en).each do |j|
    pos = j
    while pos > start && arr[pos] <= arr[pos - 1]
      arr[pos], arr[pos - 1] = arr[pos - 1], arr[pos]
      pos -= 1
    end
  end
end

def weave_merge(arr, min, max, mid)
  target = mid - min
  (1..target).each do |i|
    multi_swap(arr, mid + i, min + (i * 2) - 1)
  end
  weave_insert(arr, min, max + 1)
end

def weave_merge_sort(arr, min, max)
  if max - min == 0
    return
  elsif max - min == 1
    arr[min], arr[max] = arr[max], arr[min] if arr[min] > arr[max]
  else
    mid = (min + max) / 2
    weave_merge_sort(arr, min, mid)
    weave_merge_sort(arr, mid + 1, max)
    weave_merge(arr, min, max, mid)
  end
end

def sort(arr)
  weave_merge_sort(arr, 0, arr.length - 1) if arr.length > 1
  return arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
