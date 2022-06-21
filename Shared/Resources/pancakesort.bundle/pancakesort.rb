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

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
sort(items)
p items
