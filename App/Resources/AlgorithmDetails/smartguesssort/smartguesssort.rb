def sort(arr)
  n = arr.length()
  loops = Array.new(n, 0)

  pair_ok = lambda do |i|
    a = arr[loops[i]]
    b = arr[loops[i + 1]]
    if a < b
      true
    elsif a == b && loops[i] < loops[i + 1]
      true
    else
      false
    end
  end

  first_failure = lambda do
    i = n - 2
    while i >= 0 && pair_ok.call(i)
      i -= 1
    end
    i
  end

  loop do
    i = first_failure.call
    break if i < 0

    (0...n).each do |pos|
      if pos >= i && loops[pos] < n - 1
        loops[pos] += 1
        break
      else
        loops[pos] = 0
      end
    end
  end

  mapped = (0...n).map { |i| arr[loops[i]] }
  (0...n).each do |i|
    arr[i] = mapped[i]
  end
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
