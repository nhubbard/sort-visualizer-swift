def sort(a)
  n = a.length
  return a if n < 2
  low, high = 0, [n, 1291].min
  while low < high
    mid = (low + high) / 2
    (mid * mid * mid >= n) ? high = mid : low = mid + 1
  end
  block = low
  run_length = block * block
  runs = (n - 1) / run_length + 1
  keys = Array.new((runs < 2) ? n : run_length) { |i| i }
  greater = lambda do |x, y, base|
    a[base + x] > a[base + y] || (a[base + x] == a[base + y] && x > y)
  end
  table_sift = lambda do |root, length, base, initial|
    j, item = root, initial
    while 2 * j + 1 < length
      j = 2 * j + 1
      j += 1 if j + 1 < length && greater.call(keys[j + 1], keys[j], base)
    end
    j = (j - 1) / 2 while j > root && greater.call(item, keys[j], base)
    while j > root
      item, keys[j] = keys[j], item
      j = (j - 1) / 2
    end
    keys[root] = item
  end
  table_sort = lambda do |start, finish|
    length = finish - start
    if length > 1
      ((length - 1) / 2).downto(0) { |i| table_sift.call(i, length, start, keys[i]) }
      (length - 1).downto(1) do |i|
        item = keys[i]
        keys[i] = keys[0]
        table_sift.call(0, i, start, item)
      end
      length.times do |i|
        next if keys[i] == i
        held = a[start + i]
        j, following = i, keys[i]
        loop do
          a[start + j] = a[start + following]
          keys[j] = j
          j, following = following, keys[following]
          break if following == i
        end
        a[start + j] = held
        keys[j] = j
      end
    end
  end
  if runs < 2
    table_sort.call(0, n)
    return a
  end
  buffer = Array.new(run_length, 0)
  heap = Array.new(runs) { |i| i }
  position = Array.new(runs, 0)
  destination = Array.new(runs, 0)
  runs.times do |run|
    start = run * run_length
    table_sort.call(start, [start + run_length, n].min)
    position[run] = destination[run] = start
  end
  less = lambda do |x, y|
    a[position[x]] < a[position[y]] || (a[position[x]] == a[position[y]] && x < y)
  end
  sift = lambda do |item, start, size|
    root = start
    while 2 * root + 2 < size
      left = 2 * root + 1
      child = less.call(heap[left], heap[left + 1]) ? left : left + 1
      break unless less.call(heap[child], item)
      heap[root] = heap[child]
      root = child
    end
    left = 2 * root + 1
    if left < size && less.call(heap[left], item)
      heap[root] = heap[left]
      root = left
    end
    heap[root] = item
  end
  ((runs - 1) / 2).downto(0) { |i| sift.call(heap[i], i, runs) }
  size = runs
  advance = lambda do |run|
    position[run] += 1
    if position[run] == [(run + 1) * run_length, n].min
      size -= 1
      sift.call(heap[size], 0, size)
    else
      sift.call(heap[0], 0, size)
    end
  end
  run_length.times do |i|
    run = heap[0]
    buffer[i] = a[position[run]]
    advance.call(run)
  end
  t = count = cursor = 0
  cursor += 1 while position[cursor] - destination[cursor] < block
  loop do
    run = heap[0]
    a[destination[cursor]] = a[position[run]]
    destination[cursor] += 1
    advance.call(run)
    count += 1
    if count == block
      keys[t] = (cursor > 0) ? destination[cursor] / block - block - 1 : -1
      t += 1
      cursor = count = 0
      cursor += 1 while position[cursor] - destination[cursor] < block
    end
    break if size == 0
  end
  finish = n
  while count > 0
    count -= 1
    destination[cursor] -= 1
    finish -= 1
    a[finish] = a[destination[cursor]]
  end
  position[-1] = finish
  keys[-1] = -1
  t = 0
  t += 1 while keys[t] != -1
  source = 0
  (1...runs).each do |run|
    break if source >= destination[0]
    while destination[run] < position[run]
      keys[t] = destination[run] / block - block
      t += 1
      t += 1 while keys[t] != -1
      block.times { |x| a[destination[run] + x] = a[source + x] }
      destination[run] += block
      source += block
    end
  end
  run_length.times { |x| a[x] = buffer[x] }
  blocks = (finish - run_length) / block
  blocks.times do |i|
    next if keys[i] == i
    block.times { |x| buffer[x] = a[run_length + i * block + x] }
    j, following = i, keys[i]
    loop do
      block.times { |x| a[run_length + j * block + x] = a[run_length + following * block + x] }
      keys[j] = j
      j, following = following, keys[following]
      break if following == i
    end
    block.times { |x| a[run_length + j * block + x] = buffer[x] }
    keys[j] = j
  end
  a
end

array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
puts sort(array).inspect
