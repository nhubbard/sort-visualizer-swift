def power_of_three(arr, pos, gap, en)
  return if pos + gap > en

  power_of_three(arr, pos, gap * 3, en)
  power_of_three(arr, pos + gap, gap * 3, en)
  power_of_three(arr, pos + 2 * gap, gap * 3, en)

  i = pos
  while i + gap < en
    if arr[i] > arr[i + gap]
      arr[i], arr[i + gap] = arr[i + gap], arr[i]
    end
    i += gap
  end
end

def recursive_comb(arr, pos, gap, en)
  return if pos + gap > en

  recursive_comb(arr, pos, gap * 2, en)
  recursive_comb(arr, pos + gap, gap * 2, en)

  power_of_three(arr, pos, gap, en)
end

def sort(arr)
  n = arr.length
  recursive_comb(arr, 0, 1, n) if n > 1
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
