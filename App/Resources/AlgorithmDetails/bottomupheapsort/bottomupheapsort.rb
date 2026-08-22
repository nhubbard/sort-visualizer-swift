def sort(arr)
  n = arr.length

  sift_down = lambda do |i, b|
    j = i
    while 2 * j + 1 < b
      j = if 2 * j + 2 < b
        (arr[2 * j + 2] > arr[2 * j + 1]) ? 2 * j + 2 : 2 * j + 1
      else
        2 * j + 1
      end
    end
    while arr[i] > arr[j]
      j = (j - 1) / 2
    end
    while j > i
      arr[i], arr[j] = arr[j], arr[i]
      j = (j - 1) / 2
    end
  end

  ((n - 1) / 2).downto(0) do |i|
    sift_down.call(i, n)
  end

  (n - 1).downto(1) do |i|
    arr[0], arr[i] = arr[i], arr[0]
    sift_down.call(0, i)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
