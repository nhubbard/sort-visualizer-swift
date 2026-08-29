def insert_to(array, a, b)
  temp = array[a]
  while a > b
    a -= 1
    array[a + 1] = array[a]
  end
  array[b] = temp
end

def multi_swap(array, a, b, len)
  (0...len).each do |i|
    array[a + i], array[b + i] = array[b + i], array[a + i]
  end
end

def rotate(array, a, m, b)
  l = m - a
  r = b - m
  while l > 0 && r > 0
    if r < l
      multi_swap(array, m - r, m, r)
      b -= r
      m -= r
      l -= r
    else
      multi_swap(array, a, m, l)
      a += l
      m += l
      r -= l
    end
  end
end

def bit_reversal(array, a, b)
  length = b - a
  m = 0
  d1 = length >> 1
  d2 = d1 + (d1 >> 1)
  i = 1
  while i < length - 1
    j = d1
    k = i
    nn = d2
    while k & 1 == 0
      j -= nn
      k >>= 1
      nn >>= 1
    end
    m += j
    if m > i
      array[a + i], array[a + m] = array[a + m], array[a + i]
    end
    i += 1
  end
end

def weave_insert(array, a, b, right_init)
  right = right_init
  i = a
  j = a + 1
  while j < b
    if right
      while i < j && array[i] <= array[j]
        i += 1
      end
    else
      while i < j && array[i] < array[j]
        i += 1
      end
    end
    if i == j
      right = !right
      j += 1
    else
      insert_to(array, j, i)
      i += 1
      j += 2
    end
  end
end

def weave_merge(array, a, m_init, b)
  return if b - a < 2
  a1 = a
  b1 = b
  right = true
  if (b - a) % 2 == 1
    if m_init - a < b - m_init
      a1 -= 1
      right = false
    else
      b1 += 1
    end
  end
  e = b1
  while e - a1 > 2
    m = (a1 + e) / 2
    p = 1
    while p * 2 <= m - a1
      p *= 2
    end
    rotate(array, m - p, m, e - p)
    m = e - p
    f = m - p
    bit_reversal(array, f, m)
    bit_reversal(array, m, e)
    bit_reversal(array, f, e)
    e = f
  end
  weave_insert(array, a, b, right)
end

def sort(array)
  n = array.length
  return if n <= 1
  d = 1
  while d < n
    d <<= 1
  end
  while d > 1
    i = 0
    dec = 0
    while i < n
      j = i
      dec += n
      while dec >= d
        dec -= d
        j += 1
      end
      k = j
      dec += n
      while dec >= d
        dec -= d
        k += 1
      end
      weave_merge(array, i, j, k)
      i = k
    end
    d /= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
