def sort(arr)
  end_index = arr.length

  comp_swap = lambda do |a, b|
    if b < end_index && arr[a] > arr[b]
      arr[a], arr[b] = arr[b], arr[a]
    end
  end

  circle = lambda do |pos, ln, gap|
    return if ln < 2
    i = 0
    while 2 * i < (ln - 1) * gap
      comp_swap.call(pos + i, pos + (ln - 1) * gap - i)
      i += gap
    end
    circle.call(pos, ln / 2, gap)
    if pos + ln * gap / 2 < end_index
      circle.call(pos + ln * gap / 2, ln / 2, gap)
    end
  end

  weave_circle = lambda do |pos, ln, gap|
    return if ln < 2
    weave_circle.call(pos, ln / 2, 2 * gap)
    weave_circle.call(pos + gap, ln / 2, 2 * gap)
    circle.call(pos, ln, gap)
  end

  padded = 1
  padded *= 2 while padded < end_index

  weave_circle.call(0, padded, 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
