def sort(arr)
  end_index = arr.length

  comp_swap = lambda do |a, b|
    if b < end_index && arr[a] > arr[b]
      arr[a], arr[b] = arr[b], arr[a]
    end
  end

  padded = 1
  padded *= 2 while padded < end_index

  i = 1
  while i < padded
    j = 1
    while j <= i
      k = 0
      while k < padded
        d = padded / i / 2
        m = 0
        l = padded / j - d
        while l >= padded / j / 2
          p = 0
          while p < d
            comp_swap.call(k + m, k + l + p)
            p += 1
            m += 1
          end
          l -= d
        end
        k += padded / j
      end
      j *= 2
    end
    i *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
