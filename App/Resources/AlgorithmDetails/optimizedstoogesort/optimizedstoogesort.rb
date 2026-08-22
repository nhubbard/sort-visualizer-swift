def forward(arr, left, right)
  while left < right
    index = right
    while left < index
      arr[left], arr[index] = arr[index], arr[left] if arr[left] > arr[index]
      left += 1
      index -= 1
    end
    left = 0
    right -= 1
  end
end

def backward(arr, left, right)
  length = right
  while left < right
    index = left
    while index < right
      arr[index], arr[right] = arr[right], arr[index] if arr[index] > arr[right]
      index += 1
      right -= 1
    end
    left += 1
    right = length
  end
end

def exchange(arr, length)
  left = 0
  right = length - 1
  while left < right
    arr[left], arr[right] = arr[right], arr[left] if arr[left] > arr[right]
    left += 1
    right -= 1
  end

  forward(arr, 0, length - 2)
  backward(arr, 1, length - 1)
end

def sort(array)
  exchange(array, array.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
