def sort(array)
  length = array.length
  a = 1
  while a < length
    b = a
    c = 0
    while b < length
      if array[b - a] > array[b]
        array[b - a], array[b] = array[b], array[b - a]
      end
      c = (c + 1) % a
      b += 1
      b += a if c == 0
    end
    a *= 2
  end

  a /= 4
  e = 1
  while a > 0
    d = e
    while d > 0
      b = (d + 1) * a
      c = 0
      while b < length
        if array[b - (d * a)] > array[b]
          array[b - (d * a)], array[b] = array[b], array[b - (d * a)]
        end
        c = (c + 1) % a
        b += 1
        b += a if c == 0
      end
      d /= 2
    end
    a /= 2
    e = (e * 2) + 1
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
