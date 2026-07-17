def sort(arr)
  n = arr.length
  loops = Array.new(n, 0)
  indexes = Array.new(n, 0)

  is_valid = lambda do
    total = 0
    for i in 0...n
      for j in 0...n
        if loops[i] == loops[j]
          total += 1
        end
      end
    end
    for i in 0...n
      for j in 0...n
        if i < j && arr[loops[i]] > arr[loops[j]]
          total += 1
        elsif i > j && arr[loops[i]] < arr[loops[j]]
          total += 1
        end
      end
    end
    total == n
  end

  loop do
    if is_valid.call
      indexes[0...n] = loops
    end
    pos = 0
    while pos < n
      if loops[pos] < n - 1
        loops[pos] += 1
        break
      else
        loops[pos] = 0
        pos += 1
      end
    end
    break if pos == n
  end

  original = arr.dup
  for i in 0...n
    arr[i] = original[indexes[i]]
  end
end

array = [0, 39, 21, 14]
sort(array)
p array
