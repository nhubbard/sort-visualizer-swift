def comp_swap(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a] if arr[a] > arr[b]
end

def split(arr, a, m, b)
  return if b - a < 2

  c, len1 = 0, (b - a) / 2
  odd = (b - a).odd?
  if odd
    if m - a > b - m
      c = a
      a += 1
    else
      b -= 1
      c = b
    end
  end
  (0...len1).each do |s|
    i = a
    (s...len1).each do |j|
      comp_swap(arr, i, m + j)
      i += 1
    end
    (0...s).each do |j|
      comp_swap(arr, i, m + j)
      i += 1
    end
  end
  if odd
    if c < m
      (0...len1).each { |j| comp_swap(arr, c, m + j) }
    else
      (0...len1).each { |j| comp_swap(arr, a + j, c) }
    end
  end
end

def sort(arr)
  n = arr.length
  d = 2
  fin = 1 << (Math.log(n - 1) / Math.log(2) + 1).to_i
  while d <= fin
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
      split(arr, i, j, k)
      i = k
    end
    d *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
