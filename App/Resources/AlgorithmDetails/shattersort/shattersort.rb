def insertion_sort(arr, start, fin)
  (start + 1...fin).each do |i|
    key = arr[i]
    j = i - 1
    while j >= start && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
  end
end

def shatter_partition(arr, start, length, num)
  window = arr[start, length]
  min_v = window.min
  max_v = window.max
  value_range = max_v - min_v + 1
  shatters = (length.to_f / num).ceil

  buckets = Array.new(shatters) { [] }
  window.each do |v|
    idx = [(v - min_v) * shatters / value_range, shatters - 1].min
    buckets[idx] << v
  end

  offsets = Array.new(shatters + 1, 0)
  (0...shatters).each { |i| offsets[i + 1] = offsets[i] + buckets[i].length }

  pos = start
  buckets.each do |bucket|
    bucket.each do |v|
      arr[pos] = v
      pos += 1
    end
  end
  offsets
end

def shatter_sort(arr, length, num)
  offsets = shatter_partition(arr, 0, length, num)
  (0...offsets.length - 1).each do |i|
    insertion_sort(arr, offsets[i], offsets[i + 1]) if offsets[i + 1] - offsets[i] > 1
  end
end

def sort(arr)
  n = arr.length
  shatter_sort(arr, n, 4)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
