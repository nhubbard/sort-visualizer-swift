def find_min_max(array, a, b)
  min_value = array[a]
  max_value = min_value
  (a + 1...b).each do |i|
    if array[i] < min_value
      min_value = array[i]
    elsif array[i] > max_value
      max_value = array[i]
    end
  end
  [min_value, max_value]
end

def insertion_sort_range(array, s, e)
  (s + 1...e).each do |i|
    j = i
    while j > s && array[j - 1] > array[j]
      array[j - 1], array[j] = array[j], array[j - 1]
      j -= 1
    end
  end
end

def sift_down(array, s, root, size)
  loop do
    largest = root
    left = 2 * root + 1
    right = 2 * root + 2
    largest = left if left < size && array[s + largest] < array[s + left]
    largest = right if right < size && array[s + largest] < array[s + right]
    break if largest == root
    array[s + root], array[s + largest] = array[s + largest], array[s + root]
    root = largest
  end
end

def heap_sort_range(array, s, e)
  size = e - s
  return if size <= 1
  i = size / 2 - 1
  while i >= 0
    sift_down(array, s, i, size)
    i -= 1
  end
  end_index = size - 1
  while end_index > 0
    array[s], array[s + end_index] = array[s + end_index], array[s]
    sift_down(array, s, 0, end_index)
    end_index -= 1
  end
end

def static_sort(array, a, b)
  min_value, max_value = find_min_max(array, a, b)
  aux_len = b - a
  count = Array.new(aux_len + 1, 0)
  offset = Array.new(aux_len + 1, 0)
  const = aux_len.to_f / (max_value - min_value + 1)

  classify = lambda { |value| ((value - min_value) * const).to_i }

  (a...b).each do |i|
    idx = classify.call(array[i])
    count[idx] += 1
  end

  offset[0] = a
  (1...aux_len).each do |i|
    offset[i] = count[i - 1] + offset[i - 1]
  end

  (0...aux_len).each do |v|
    while count[v] > 0
      origin = offset[v]
      frm = origin
      num = array[frm]
      array[frm] = -1
      loop do
        idx = classify.call(num)
        to = offset[idx]
        offset[idx] += 1
        count[idx] -= 1
        temp = array[to]
        array[to] = num
        num = temp
        frm = to
        break if frm == origin
      end
    end
  end

  (0...aux_len).each do |i|
    s = i > 1 ? offset[i - 1] : a
    e = offset[i]
    next if e - s <= 1
    if e - s > 16
      heap_sort_range(array, s, e)
    else
      insertion_sort_range(array, s, e)
    end
  end
end

def sort(arr)
  static_sort(arr, 0, arr.length) if arr.length > 1
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
