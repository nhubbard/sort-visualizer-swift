def merge(arr, flags, i, j)
  if arr[i] < arr[j]
    flags[j] = !flags[j]
    arr[i], arr[j] = arr[j], arr[i]
  end
end

def sort(arr)
  n = arr.length
  flags = Array.new(n, false)

  (n - 1).downto(1) do |i|
    j = i
    while (j & 1) == (flags[j >> 1] ? 1 : 0)
      j >>= 1
    end
    gparent = j >> 1
    merge(arr, flags, gparent, i)
  end

  (n - 1).downto(2) do |i|
    arr[0], arr[i] = arr[i], arr[0]
    x = 1
    loop do
      y = 2 * x + (flags[x] ? 1 : 0)
      break if y >= i
      x = y
    end
    while x > 0
      merge(arr, flags, 0, x)
      x >>= 1
    end
  end
  arr[0], arr[1] = arr[1], arr[0]
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
