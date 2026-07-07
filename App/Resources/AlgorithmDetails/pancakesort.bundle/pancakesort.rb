def flip(arr, n)
  left = 0
  while left < n
    arr[left], arr[n] = arr[n], arr[left]
    n -= 1
    left += 1
  end
end

def max_index(arr, n)
  index = 0
  for i in 0..(n - 1)
    if arr[i] > arr[index]
      index = i
    end
  end
  return index
end

def sort(arr)
  n = arr.length()
  while n > 1
    max = max_index(arr, n)
    if max != n
      flip(arr, max)
      flip(arr, n - 1)
    end
    n -= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array