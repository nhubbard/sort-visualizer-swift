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

def floor_log2(n)
  log = 0
  m = n
  while m > 1
    m >>= 1
    log += 1
  end
  log
end

def simple_shatter_sort(arr, length, num, rate)
  i = num
  while i > 1
    shatter_partition(arr, 0, length, i)
    i /= rate
  end
  offsets = shatter_partition(arr, 0, length, 1)
  (0...offsets.length - 1).each do |k|
    insertion_sort(arr, offsets[k], offsets[k + 1]) if offsets[k + 1] - offsets[k] > 1
  end
end

def sort(arr)
  n = arr.length
  rate = [2, floor_log2(n) / 2].max
  simple_shatter_sort(arr, n, 4, rate)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
