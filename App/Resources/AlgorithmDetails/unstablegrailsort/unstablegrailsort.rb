def swap(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a]
end

def multi_swap(arr, a, b, count)
  count.times { |i| swap(arr, a + i, b + i) }
end

def rotate(arr, pos, len_a, len_b)
  while len_a != 0 && len_b != 0
    if len_a <= len_b
      multi_swap(arr, pos, pos + len_a, len_a)
      pos += len_a
      len_b -= len_a
    else
      multi_swap(arr, pos + (len_a - len_b), pos + len_a, len_b)
      len_a -= len_b
    end
  end
end

def insert_sort(arr, pos, len)
  (1...len).each do |i|
    j = pos + i
    while j > pos && arr[j] < arr[j - 1]
      swap(arr, j, j - 1)
      j -= 1
    end
  end
end

def bin_search(arr, pos, len, key_pos, is_left)
  left = -1
  right = len
  key = arr[key_pos]
  while left < right - 1
    mid = left + (right - left) / 2
    cond = is_left ? (arr[pos + mid] >= key) : (arr[pos + mid] > key)
    if cond
      right = mid
    else
      left = mid
    end
  end
  right
end

def merge_without_buffer(arr, pos, len1, len2)
  return if len1 == 0 || len2 == 0
  if len1 + len2 == 2
    swap(arr, pos, pos + 1) if arr[pos] > arr[pos + 1]
    return
  end
  if len1 > len2
    mid1 = len1 / 2
    mid2 = bin_search(arr, pos + len1, len2, pos + mid1, true)
  else
    mid2 = len2 / 2
    mid1 = bin_search(arr, pos, len1, pos + len1 + mid2, false)
  end
  rotate(arr, pos + mid1, len1 - mid1, mid2)
  merge_without_buffer(arr, pos, mid1, mid2)
  merge_without_buffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2)
end

def merge_left(arr, pos, left_len, right_len, dist)
  left = 0
  right = left_len
  right_len += left_len
  while right < right_len
    if left == left_len || arr[pos + left] > arr[pos + right]
      swap(arr, pos + dist, pos + right)
      dist += 1
      right += 1
    else
      swap(arr, pos + dist, pos + left)
      dist += 1
      left += 1
    end
  end
  multi_swap(arr, pos + dist, pos + left, left_len - left) if dist != left
end

def merge_right(arr, pos, left_len, right_len, dist)
  merged_pos = left_len + right_len + dist - 1
  right = left_len + right_len - 1
  left = left_len - 1
  while left >= 0
    if right < left_len || arr[pos + left] > arr[pos + right]
      swap(arr, pos + merged_pos, pos + left)
      merged_pos -= 1
      left -= 1
    else
      swap(arr, pos + merged_pos, pos + right)
      merged_pos -= 1
      right -= 1
    end
  end
  while right != merged_pos && right >= left_len
    swap(arr, pos + merged_pos, pos + right)
    merged_pos -= 1
    right -= 1
  end
end

def smart_merge_with_buffer(arr, pos, left_over_len, block_len)
  dist = -block_len
  left = 0
  right = left_over_len
  left_end = right
  right_end = right + block_len
  while left < left_end && right < right_end
    if arr[pos + left] <= arr[pos + right]
      swap(arr, pos + dist, pos + left)
      dist += 1
      left += 1
    else
      swap(arr, pos + dist, pos + right)
      dist += 1
      right += 1
    end
  end
  if left < left_end
    length = left_end - left
    while left < left_end
      left_end -= 1
      right_end -= 1
      swap(arr, pos + left_end, pos + right_end)
    end
  else
    length = right_end - right
  end
  length
end

def merge_buffers_left(arr, pos, block_count, block_len, a_block_count, last_len)
  if block_count == 0
    merge_left(arr, pos, a_block_count * block_len, last_len, -block_len)
    return
  end
  left_over_len = block_len
  process_index = block_len
  (1...block_count).each do |_key_index|
    rest_to_process = process_index - left_over_len
    left_over_len = smart_merge_with_buffer(arr, pos + rest_to_process, left_over_len, block_len)
    process_index += block_len
  end
  rest_to_process = process_index - left_over_len
  if last_len != 0
    left_over_len += block_len * a_block_count
    merge_left(arr, pos + rest_to_process, left_over_len, last_len, -block_len)
  else
    multi_swap(arr, pos + rest_to_process, pos + rest_to_process - block_len, left_over_len)
  end
end

def build_blocks(arr, pos, length, build_len)
  dist = 1
  while dist < length
    extra_dist = arr[pos + dist - 1] > arr[pos + dist] ? 1 : 0
    swap(arr, pos + dist - 3, pos + dist - 1 + extra_dist)
    swap(arr, pos + dist - 2, pos + dist - extra_dist)
    dist += 2
  end
  swap(arr, pos + length - 1, pos + length - 3) if length.odd?
  pos -= 2
  part = 2
  while part < build_len
    left = 0
    right = length - 2 * part
    while left <= right
      merge_left(arr, pos + left, part, part, -part)
      left += 2 * part
    end
    rest = length - left
    if rest > part
      merge_left(arr, pos + left, part, rest - part, -part)
    else
      rotate(arr, pos + left - part, part, rest)
    end
    pos -= part
    part *= 2
  end
  rest_to_build = length % (2 * build_len)
  left_over_pos = length - rest_to_build
  if rest_to_build <= build_len
    rotate(arr, pos + left_over_pos, rest_to_build, build_len)
  else
    merge_right(arr, pos + left_over_pos, build_len, rest_to_build - build_len, build_len)
  end
  while left_over_pos > 0
    left_over_pos -= 2 * build_len
    merge_right(arr, pos + left_over_pos, build_len, build_len, build_len)
  end
end

def combine_blocks(arr, pos, length, build_len, reg_block_len)
  combine_len = length / (2 * build_len)
  left_over = length % (2 * build_len)
  if left_over <= build_len
    length -= left_over
    left_over = 0
  end
  i = 0
  while i <= combine_len
    break if i == combine_len && left_over == 0

    block_pos = pos + i * 2 * build_len
    block_count = (i == combine_len ? left_over : 2 * build_len) / reg_block_len
    (1...block_count).each do |index|
      left_index = index - 1
      (index...block_count).each do |right_index|
        a = arr[block_pos + left_index * reg_block_len]
        b = arr[block_pos + right_index * reg_block_len]
        cmp = a <=> b
        if cmp > 0 || (cmp == 0 && arr[block_pos + (left_index + 1) * reg_block_len - 1] >
                       arr[block_pos + (right_index + 1) * reg_block_len - 1])
          left_index = right_index
        end
      end
      if left_index != index - 1
        multi_swap(arr, block_pos + (index - 1) * reg_block_len, block_pos + left_index * reg_block_len, reg_block_len)
      end
    end
    a_block_count = 0
    last_len = i == combine_len ? (left_over % reg_block_len) : 0
    if last_len != 0
      while a_block_count < block_count && arr[block_pos + block_count * reg_block_len] < arr[
        block_pos + (block_count - a_block_count - 1) * reg_block_len
      ]
        a_block_count += 1
      end
    end
    merge_buffers_left(arr, block_pos, block_count - a_block_count, reg_block_len, a_block_count, last_len)
    i += 1
  end
  while length > 0
    length -= 1
    swap(arr, pos + length, pos + length - reg_block_len)
  end
end

def common_sort(arr, pos, length)
  if length <= 16
    insert_sort(arr, pos, length)
    return
  end
  block_len = 1
  block_len *= 2 while block_len * block_len < length
  build_len = block_len
  build_blocks(arr, pos + block_len, length - block_len, build_len)
  loop do
    build_len *= 2
    break if length - block_len <= build_len

    combine_blocks(arr, pos + block_len, length - block_len, build_len, block_len)
  end
  insert_sort(arr, pos, block_len)
  merge_without_buffer(arr, pos, block_len, length - block_len)
end

def sort(arr)
  common_sort(arr, 0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
