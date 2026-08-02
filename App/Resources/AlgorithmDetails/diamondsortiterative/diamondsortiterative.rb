def sort(arr)
  n = arr.length

  comp_swap = lambda do |a, b|
    arr[a], arr[b] = arr[b], arr[a] if arr[a] > arr[b]
  end

  pow = 1
  pow *= 2 while pow < n

  m = 4
  while m <= pow
    (0...(m / 2)).each do |k|
      cnt = (k <= m / 4) ? k : m / 2 - k
      j = 0
      while j < n
        if j + cnt + 1 < n
          i = j + cnt
          while i + 1 < [n, j + m - cnt].min
            comp_swap.call(i, i + 1)
            i += 2
          end
        end
        j += m
      end
    end
    m *= 2
  end
  m /= 2
  (0..(m / 2)).each do |k|
    i = k
    while i + 1 < [n, m - k].min
      comp_swap.call(i, i + 1)
      i += 2
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
