def merge_exchange_sort(array)
  n = array.length
  return if n <= 1
  t = (Math.log(n - 1) / Math.log(2)).to_i + 1
  p0 = 1 << (t - 1)
  p = p0
  while p > 0
    q = p0
    r = 0
    d = p
    loop do
      i = 0
      while i < n - d
        if (i & p) == r && array[i] > array[i + d]
          array[i], array[i + d] = array[i + d], array[i]
        end
        i += 1
      end
      break if q == p
      d = q - p
      q >>= 1
      r = p
    end
    p >>= 1
  end
end

def sort(array)
  merge_exchange_sort(array)
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
