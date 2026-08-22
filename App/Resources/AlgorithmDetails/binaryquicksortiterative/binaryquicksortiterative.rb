def most_significant_bit(value)
  return -1 if value == 0
  bit = 0
  bit += 1 while (value >> (bit + 1)) != 0
  bit
end

def partition(arr, p, r, bit)
  i = p - 1
  j = r + 1
  loop do
    i += 1
    i += 1 while i <= r && ((arr[i] >> bit) & 1) == 0
    j -= 1
    j -= 1 while j >= p && ((arr[j] >> bit) & 1) == 1
    if i < j
      arr[i], arr[j] = arr[j], arr[i]
    else
      return j
    end
  end
end

def sort(arr)
  n = arr.length
  bit = most_significant_bit(arr.max)

  tasks = [[0, n - 1, bit]]
  until tasks.empty?
    p, r, b = tasks.shift
    if p < r && b >= 0
      q = partition(arr, p, r, b)
      tasks << [p, q, b - 1]
      tasks << [q + 1, r, b - 1]
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
