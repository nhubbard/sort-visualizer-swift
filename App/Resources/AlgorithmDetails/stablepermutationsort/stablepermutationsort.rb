def sort(arr)
  n = arr.length
  idx = (0...n).to_a

  is_sorted = lambda do |a|
    (1...a.length).each do |i|
      return false if a[i] < a[i - 1]
    end
    true
  end

  permute = lambda do |length|
    if length < 2
      return is_sorted.call(arr)
    end
    (length - 2).downto(0) do |i|
      if permute.call(length - 1)
        return true
      end
      arr[idx[i]], arr[idx[length - 1]] = arr[idx[length - 1]], arr[idx[i]]
      idx[i], idx[length - 1] = idx[length - 1], idx[i]
    end
    return true if permute.call(length - 1)
    t = idx[length - 1]
    (length - 1).downto(1) do |i|
      idx[i] = idx[i - 1]
    end
    idx[0] = t
    t = arr[idx[0]]
    (1...length).each do |i|
      arr[idx[i - 1]] = arr[idx[i]]
    end
    arr[idx[length - 1]] = t
    false
  end

  permute.call(n)
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
