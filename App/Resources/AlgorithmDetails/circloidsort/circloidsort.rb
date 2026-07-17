def circle(array, left, right)
  a = left
  b = right
  swapped = false
  while a < b
    if array[a] > array[b]
      array[a], array[b] = array[b], array[a]
      swapped = true
    end
    a += 1
    b -= 1
    if a == b
      b += 1
    end
  end
  swapped
end

def circle_pass(array, left, right)
  return false if left >= right
  mid = (left + right) / 2
  l = circle_pass(array, left, mid)
  r = circle_pass(array, mid + 1, right)
  circle(array, left, right) || l || r
end

def sort(arr)
  n = arr.length
  return if n <= 1
  while circle_pass(arr, 0, n - 1)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
