def most_significant_bit(value)
  return -1 if value == 0
  bit = 0
  bit += 1 while (value >> (bit + 1)) != 0
  bit
end

def get_bit(value, bit)
  (value >> bit) & 1 == 1
end

def partition(arr, lo, hi, bit)
  i = lo - 1
  j = hi
  loop do
    i += 1
    i += 1 while i < j && !get_bit(arr[i], bit)
    j -= 1
    j -= 1 while j > i && get_bit(arr[j], bit)
    if i < j
      arr[i], arr[j] = arr[j], arr[i]
    else
      return i
    end
  end
end

def sort(arr)
  n = arr.length
  return if n <= 1

  q = most_significant_bit(arr.max)
  return if q < 0

  m = 0
  i = 0
  b = n

  while i < n
    p = (b - i < 1) ? i : partition(arr, i, b, q)

    if q == 0
      m += 2
      q += 1 until get_bit(m, q + 1)
      i = b
      b += 1 while b < n && (arr[b] >> (q + 1)) == (m >> (q + 1))
    else
      b = p
      q -= 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
