def sort(arr)
  length = arr.length
  return if length < 2
  block_swap = lambda do |a, b, size|
    size.times do |offset|
      x = a - size + 1 + offset
      y = b - size + 1 + offset
      arr[x], arr[y] = arr[y], arr[x]
    end
  end
  block_insert = lambda do |a, b, size|
    while a - size >= b
      block_swap.call(a - size, a, size)
      a -= size
    end
  end
  block_reversal = lambda do |a, b, size|
    b -= size
    while b > a
      block_swap.call(a, b, size)
      a += size
      b -= size
    end
  end
  block_search = lambda do |a, b, size, value|
    while a < b
      mid = a + (((b - a) / size) / 2) * size
      if value < arr[mid]
        b = mid
      else
        a = mid + size
      end
    end
    a
  end
  order = lambda do |a, b, size|
    i = a
    j = i + size
    while j < b
      block_insert.call(j, i, size)
      i += size
      j += 2 * size
    end
    mid = a + (((b - a) / size) / 2) * size
    block_reversal.call(mid, b, size)
  end
  k = 1
  while 2 * k <= length
    i = 2 * k - 1
    while i < length
      block_swap.call(i - k, i, k) if arr[i - k] > arr[i]
      i += 2 * k
    end
    k *= 2
  end
  while k > 0
    a = k - 1
    i = a + 2 * k
    g, p = 2, 4
    while i + 2 * k * g - k <= length
      order.call(i, i + 2 * k * g - k, k)
      b = a + k * (p - 1)
      i += k * g - k
      j = i
      while j < i + k * g
        block_insert.call(j, block_search.call(a, b, k, arr[j]), k)
        j += k
      end
      i += k * g + k
      g = p - g
      p *= 2
    end
    while i < length
      block_insert.call(i, block_search.call(a, i, k, arr[i]), k)
      i += 2 * k
    end
    k /= 2
  end
end

array = [34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60]
sort(array)
p array
