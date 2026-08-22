def sort(arr)
  n = arr.length
  loops = Array.new(n, 0)

  is_valid = lambda do
    (0...n - 1).each do |i|
      a = arr[loops[i]]
      b = arr[loops[i + 1]]
      if a < b || (a == b && loops[i] < loops[i + 1])
        next
      end
      return false
    end
    true
  end

  until is_valid.call
    (0...n).each do |pos|
      if loops[pos] < n - 1
        loops[pos] += 1
        break
      else
        loops[pos] = 0
      end
    end
  end

  mapped = loops.map { |i| arr[i] }
  (0...n).each do |i|
    arr[i] = mapped[i]
  end
end

array = [0, 39, 21, 62, 14]
sort(array)
p array
