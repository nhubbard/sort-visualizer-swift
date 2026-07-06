THRESHOLD = 32

def insertion_sort(arr, start, stop)
  ((start + 1)...stop).each do |i|
    j = i
    while j > start && arr[j] < arr[j - 1]
      arr[j - 1], arr[j] = arr[j], arr[j - 1]
      j -= 1
    end
  end
end

def merge(arr, start, mid, stop)
  low = start
  high = mid
  merged = []
  while low < mid && high < stop
    if arr[high] < arr[low]
      merged << arr[high]
      high += 1
    else
      merged << arr[low]
      low += 1
    end
  end
  while low < mid
    merged << arr[low]
    low += 1
  end
  while high < stop
    merged << arr[high]
    high += 1
  end
  merged.each_with_index do |value, i|
    arr[start + i] = value
  end
end

def merge_sort(arr, start, stop)
  if stop - start <= THRESHOLD
    insertion_sort(arr, start, stop)
    return
  end
  mid = start + (stop - start) / 2
  merge_sort(arr, start, mid)
  merge_sort(arr, mid, stop)
  merge(arr, start, mid, stop)
end

def sort(arr)
  n = arr.length()
  return if n < 2
  merge_sort(arr, 0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
