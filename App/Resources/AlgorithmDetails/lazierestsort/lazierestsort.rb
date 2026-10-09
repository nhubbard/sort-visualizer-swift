def reverse(arr, a, b)
  b -= 1
  while a < b
    arr[a], arr[b] = arr[b], arr[a]
    a += 1
    b -= 1
  end
end

def rotate(arr, a, m, b)
  reverse(arr, a, m)
  reverse(arr, m, b)
  reverse(arr, a, b)
end

def search(arr, a, b, value, upper)
  while a < b
    mid = (a + b) / 2
    if upper ? value < arr[mid] : value <= arr[mid]
      b = mid
    else
      a = mid + 1
    end
  end
  a
end

def gallop(arr, a, b, value, backwards)
  step = 1
  if backwards
    step *= 2 while b - step >= a && value < arr[b - step]
    search(arr, [a, b - step + 1].max, b - step / 2, value, true)
  else
    step *= 2 while a - 1 + step < b && value > arr[a - 1 + step]
    search(arr, a + step / 2, [b, a - 1 + step].min, value, false)
  end
end

def insertion(arr, a, b)
  (a + 1...b).each do |i|
    value = arr[i]
    position = search(arr, a, i, value, true)
    j = i
    while j > position
      arr[j] = arr[j - 1]
      j -= 1
    end
    arr[position] = value
  end
end

def forward(arr, a, m, b)
  i = a
  j = m
  while i < j && j < b
    if arr[i] > arr[j]
      k = gallop(arr, j + 1, b, arr[i], false)
      rotate(arr, i, j, k)
      i += k - j
      j = k
    else
      i += 1
    end
  end
end

def backward(arr, a, m, b)
  i = m - 1
  j = b - 1
  while j > i && i >= a
    if arr[i] > arr[j]
      k = gallop(arr, a, i, arr[j], true)
      rotate(arr, k, i + 1, j + 1)
      j -= i + 1 - k
      i = k - 1
    else
      j -= 1
    end
  end
end

def merge(arr, a, m, b)
  if b - m < m - a
    backward(arr, a, m, b)
  else
    forward(arr, a, m, b)
  end
end

def fragmented(arr, a, m, b, size)
  i = a + (m - a) % size
  while i < m
    j = gallop(arr, m, b, arr[i], false)
    rotate(arr, i, m, j)
    length = j - m
    boundary = i
    i += length
    m += length
    merge(arr, a, boundary, i)
    a = i
    i += size
  end
  merge(arr, [a, i - size].max, i, b)
end

def sort(arr)
  n = arr.length
  if n <= 16
    insertion(arr, 0, n)
    return
  end
  size = 1
  size += 1 while size**3 < n
  group = size * size
  (n % size..n).step(size) { |i| insertion(arr, [0, i - size].max, i) }
  i = n - size
  j = n
  while i > 0
    if j - i == group
      j -= group
      i -= size
    end
    forward(arr, [0, i - size].max, i, j)
    i -= size
  end
  i = n - group
  while i > 0
    fragmented(arr, [0, i - group].max, i, n, size)
    i -= group
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
  10, 2, 95, 46, 21, 74, 6, 38]
sort(array)
p array
