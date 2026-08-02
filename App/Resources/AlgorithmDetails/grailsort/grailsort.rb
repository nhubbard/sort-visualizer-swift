def swap(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a]
end

def compare_values(a, b)
  a <=> b
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

def find_keys(arr, pos, len, num_keys)
  dist = 1
  found_keys = 1
  first_key = 0
  while dist < len && found_keys < num_keys
    loc = bin_search(arr, pos + first_key, found_keys, pos + dist, true)
    if loc == found_keys || arr[pos + dist] != arr[pos + first_key + loc]
      rotate(arr, pos + first_key, found_keys, dist - (first_key + found_keys))
      first_key = dist - found_keys
      rotate(arr, pos + (first_key + loc), found_keys - loc, 1)
      found_keys += 1
    end
    dist += 1
  end
  rotate(arr, pos, first_key, found_keys)
  found_keys
end

def merge_without_buffer(arr, pos, len1, len2)
  return if len1 == 0 || len2 == 0
  if len1 < len2
    while len1 != 0
      loc = bin_search(arr, pos + len1, len2, pos, true)
      if loc != 0
        rotate(arr, pos, len1, loc)
        pos += loc
        len2 -= loc
      end
      break if len2 == 0

      begin
        pos += 1
        len1 -= 1
      end while len1 != 0 && arr[pos] <= arr[pos + len1]
    end
  else
    while len2 != 0
      loc = bin_search(arr, pos, len1, pos + len1 + len2 - 1, false)
      if loc != len1
        rotate(arr, pos + loc, len1 - loc, len2)
        len1 = loc
      end
      break if len1 == 0

      begin
        len2 -= 1
      end while len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
    end
  end
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

def smart_merge_without_buffer(arr, pos, left_over_len, left_over_frag, reg_block_len)
  return [left_over_len, left_over_frag] if reg_block_len == 0

  len1 = left_over_len
  len2 = reg_block_len
  type_frag = 1 - left_over_frag
  if len1 != 0 && (compare_values(arr[pos + len1 - 1], arr[pos + len1]) - type_frag) >= 0
    while len1 != 0
      found_len = bin_search(arr, pos + len1, len2, pos, type_frag != 0)
      if found_len != 0
        rotate(arr, pos, len1, found_len)
        pos += found_len
        len2 -= found_len
      end
      return [len1, left_over_frag] if len2 == 0

      begin
        pos += 1
        len1 -= 1
      end while len1 != 0 && (compare_values(arr[pos], arr[pos + len1]) - type_frag) < 0
    end
  end
  [len2, type_frag]
end

def smart_merge_with_buffer(arr, pos, left_over_len, left_over_frag, block_len)
  dist = -block_len
  left = 0
  right = left_over_len
  left_end = right
  right_end = right + block_len
  type_frag = 1 - left_over_frag
  while left < left_end && right < right_end
    if (compare_values(arr[pos + left], arr[pos + right]) - type_frag) < 0
      swap(arr, pos + dist, pos + left)
      dist += 1
      left += 1
    else
      swap(arr, pos + dist, pos + right)
      dist += 1
      right += 1
    end
  end
  fragment = left_over_frag
  if left < left_end
    length = left_end - left
    while left < left_end
      left_end -= 1
      right_end -= 1
      swap(arr, pos + left_end, pos + right_end)
    end
  else
    length = right_end - right
    fragment = type_frag
  end
  [length, fragment]
end

def merge_buffers_left(arr, keys_pos, midkey, pos, block_count, block_len, havebuf, a_block_count, last_len)
  if block_count == 0
    a_blocks_len = a_block_count * block_len
    if havebuf
      merge_left(arr, pos, a_blocks_len, last_len, -block_len)
    else
      merge_without_buffer(arr, pos, a_blocks_len, last_len)
    end
    return
  end
  left_over_len = block_len
  left_over_frag = arr[keys_pos] < arr[midkey] ? 0 : 1
  process_index = block_len
  (1...block_count).each do |key_index|
    rest_to_process = process_index - left_over_len
    next_frag = arr[keys_pos + key_index] < arr[midkey] ? 0 : 1
    if next_frag == left_over_frag
      multi_swap(arr, pos + rest_to_process - block_len, pos + rest_to_process, left_over_len) if havebuf
      rest_to_process = process_index
      left_over_len = block_len
    else
      left_over_len, left_over_frag = if havebuf
        smart_merge_with_buffer(arr, pos + rest_to_process, left_over_len, left_over_frag, block_len)
      else
        smart_merge_without_buffer(arr, pos + rest_to_process, left_over_len, left_over_frag, block_len)
      end
    end
    process_index += block_len
  end
  rest_to_process = process_index - left_over_len
  if last_len != 0
    if left_over_frag != 0
      multi_swap(arr, pos + rest_to_process - block_len, pos + rest_to_process, left_over_len) if havebuf
      rest_to_process = process_index
      left_over_len = block_len * a_block_count
      left_over_frag = 0
    else
      left_over_len += block_len * a_block_count
    end
    if havebuf
      merge_left(arr, pos + rest_to_process, left_over_len, last_len, -block_len)
    else
      merge_without_buffer(arr, pos + rest_to_process, left_over_len, last_len)
    end
  else
    multi_swap(arr, pos + rest_to_process, pos + rest_to_process - block_len, left_over_len) if havebuf
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

def combine_blocks(arr, key_pos, pos, length, build_len, reg_block_len, havebuf)
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
    insert_sort(arr, key_pos, block_count + (i == combine_len ? 1 : 0))
    midkey = build_len / reg_block_len
    (1...block_count).each do |index|
      left_index = index - 1
      (index...block_count).each do |right_index|
        a = arr[block_pos + left_index * reg_block_len]
        b = arr[block_pos + right_index * reg_block_len]
        if a > b || (a == b && arr[key_pos + left_index] > arr[key_pos + right_index])
          left_index = right_index
        end
      end
      if left_index != index - 1
        multi_swap(arr, block_pos + (index - 1) * reg_block_len, block_pos + left_index * reg_block_len, reg_block_len)
        swap(arr, key_pos + (index - 1), key_pos + left_index)
        midkey ^= (index - 1) ^ left_index if midkey == index - 1 || midkey == left_index
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
    merge_buffers_left(arr, key_pos, key_pos + midkey, block_pos, block_count - a_block_count,
                        reg_block_len, havebuf, a_block_count, last_len)
    i += 1
  end
  if havebuf
    while length > 0
      length -= 1
      swap(arr, pos + length, pos + length - reg_block_len)
    end
  end
end

def lazy_stable_sort(arr, pos, length)
  dist = 1
  while dist < length
    swap(arr, pos + dist - 1, pos + dist) if arr[pos + dist - 1] > arr[pos + dist]
    dist += 2
  end
  part = 2
  while part < length
    left = 0
    right = length - 2 * part
    while left <= right
      merge_without_buffer(arr, pos + left, part, part)
      left += 2 * part
    end
    rest = length - left
    merge_without_buffer(arr, pos + left, part, rest - part) if rest > part
    part *= 2
  end
end

def common_sort(arr, pos, length)
  if length <= 16
    insert_sort(arr, pos, length)
    return
  end
  block_len = 1
  block_len *= 2 while block_len * block_len < length
  num_keys = (length - 1) / block_len + 1
  keys_found = find_keys(arr, pos, length, num_keys + block_len)
  buffer_enabled = true
  if keys_found < num_keys + block_len
    if keys_found < 4
      lazy_stable_sort(arr, pos, length)
      return
    end
    num_keys = block_len
    num_keys /= 2 while num_keys > keys_found
    buffer_enabled = false
    block_len = 0
  end
  dist = block_len + num_keys
  build_len = buffer_enabled ? block_len : num_keys
  build_blocks(arr, pos + dist, length - dist, build_len)
  loop do
    build_len *= 2
    break if length - dist <= build_len

    reg_block_len = block_len
    build_buf_enabled = buffer_enabled
    unless buffer_enabled
      if num_keys > 4 && (num_keys / 8) * num_keys >= build_len
        reg_block_len = num_keys / 2
        build_buf_enabled = true
      else
        calc_keys = 1
        i = build_len * keys_found / 2
        while calc_keys < num_keys && i != 0
          calc_keys *= 2
          i /= 8
        end
        reg_block_len = (2 * build_len) / calc_keys
      end
    end
    combine_blocks(arr, pos, pos + dist, length - dist, build_len, reg_block_len, build_buf_enabled)
  end
  insert_sort(arr, pos, dist)
  merge_without_buffer(arr, pos, dist, length - dist)
end

def sort(arr)
  common_sort(arr, 0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
