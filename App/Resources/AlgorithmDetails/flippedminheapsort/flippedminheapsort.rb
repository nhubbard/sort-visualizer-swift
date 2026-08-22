def sort(arr)
  n = arr.length

  idx = lambda do |p|
    n - p
  end

  sift_down = lambda do |root, dist|
    while root <= dist / 2
      leaf = 2 * root
      if leaf < dist && arr[idx.call(leaf)] > arr[idx.call(leaf + 1)]
        leaf += 1
      end
      if arr[idx.call(root)] > arr[idx.call(leaf)]
        arr[idx.call(root)], arr[idx.call(leaf)] = arr[idx.call(leaf)], arr[idx.call(root)]
        root = leaf
      else
        break
      end
    end
  end

  i = n / 2
  while i >= 1
    sift_down.call(i, n)
    i -= 1
  end

  i = n
  while i > 1
    arr[idx.call(1)], arr[idx.call(i)] = arr[idx.call(i)], arr[idx.call(1)]
    sift_down.call(1, i - 1)
    i -= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
