def sort(arr)
  n = arr.length

  is_sorted = lambda do
    result = true
    (0...n - 1).each do |i|
      if arr[i] > arr[i + 1]
        result = false
        break
      end
    end
    result
  end

  permutation_sort = lambda do |depth|
    if depth >= n - 1
      is_sorted.call
    else
      found = false
      (n - 1).downto(depth + 1) do |i|
        if permutation_sort.call(depth + 1)
          found = true
          break
        end
        if (n - depth) % 2 == 0
          arr[depth], arr[i] = arr[i], arr[depth]
        else
          arr[depth], arr[n - 1] = arr[n - 1], arr[depth]
        end
      end
      found || permutation_sort.call(depth + 1)
    end
  end

  permutation_sort.call(0)
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
