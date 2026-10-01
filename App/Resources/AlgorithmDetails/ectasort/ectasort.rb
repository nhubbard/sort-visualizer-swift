def sort(arr)
  n = arr.length
  return if n < 2

  run = n
  run = (run + 1) / 2 while run >= 32

  insertion = lambda do |start, finish|
    ((start + 1)...finish).each do |i|
      value = arr[i]
      low = start
      high = i
      while low < high
        middle = (low + high) / 2
        if arr[middle] > value
          high = middle
        else
          low = middle + 1
        end
      end
      i.downto(low + 1) { |j| arr[j] = arr[j - 1] }
      arr[low] = value
    end
  end

  if n <= 32
    insertion.call(0, n)
    return
  end
  half = n / 2
  buffer = arr[half, half]

  merge_backward = lambda do |start, middle, finish, workspace|
    count = finish - middle
    arr[workspace, count] = arr[middle, count]
    left = middle - 1
    right = workspace + count - 1
    output = finish - 1
    while left >= start && right >= workspace
      if arr[left] > arr[right]
        arr[output] = arr[left]
        left -= 1
      else
        arr[output] = arr[right]
        right -= 1
      end
      output -= 1
    end
    while right >= workspace
      arr[output] = arr[right]
      right -= 1
      output -= 1
    end
  end

  sort_segment = lambda do |start, finish, workspace|
    (start...finish).step(run) do |lower|
      insertion.call(lower, [lower + run, finish].min)
    end
    width = run
    while width < finish - start
      (start...finish).step(2 * width) do |lower|
        middle = [lower + width, finish].min
        upper = [lower + 2 * width, finish].min
        merge_backward.call(lower, middle, upper, workspace) if middle < upper
      end
      width *= 2
    end
  end

  sort_segment.call(0, half, half)
  arr[half, half] = buffer
  buffer = arr[0, half]
  sort_segment.call(half, n, 0)
  left = 0
  right = half
  output = 0
  while left < half && right < n
    if buffer[left] <= arr[right]
      arr[output] = buffer[left]
      left += 1
    else
      arr[output] = arr[right]
      right += 1
    end
    output += 1
  end
  while left < half
    arr[output] = buffer[left]
    left += 1
    output += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
