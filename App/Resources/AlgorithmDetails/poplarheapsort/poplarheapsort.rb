def hyperfloor(n)
  power = 1
  power *= 2 while power * 2 <= n
  power
end

def unchecked_insertion_sort(array, first, last)
  cur = first + 1
  while cur != last
    if array[cur] < array[cur - 1]
      tmp = array[cur]
      sift = cur
      sift1 = cur - 1
      loop do
        array[sift] = array[sift1]
        sift -= 1
        break if sift == first
        sift1 -= 1
        break if tmp >= array[sift1]
      end
      array[sift] = tmp
    end
    cur += 1
  end
end

def insertion_sort(array, first, last)
  return if first == last
  unchecked_insertion_sort(array, first, last)
end

def poplar_sift(array, first_in, size_in)
  size = size_in
  return if size < 2
  root = first_in + (size - 1)
  child_root1 = root - 1
  child_root2 = first_in + (size / 2 - 1)
  loop do
    max_root = root
    max_root = child_root1 if array[max_root] < array[child_root1]
    max_root = child_root2 if array[max_root] < array[child_root2]
    return if max_root == root
    array[root], array[max_root] = array[max_root], array[root]
    size /= 2
    return if size < 2
    root = max_root
    child_root1 = root - 1
    child_root2 = max_root - (size - size / 2)
  end
end

def pop_heap_with_size(array, first, last, size_in)
  size = size_in
  poplar_size = hyperfloor(size + 1) - 1
  last_root = last - 1
  bigger = last_root
  bigger_size = poplar_size

  pos = first
  loop do
    root = pos + poplar_size - 1
    break if root == last_root
    if array[bigger] < array[root]
      bigger = root
      bigger_size = poplar_size
    end
    pos = root + 1
    size -= poplar_size
    poplar_size = hyperfloor(size + 1) - 1
  end

  return if bigger == last_root
  array[bigger], array[last_root] = array[last_root], array[bigger]
  poplar_sift(array, bigger - (bigger_size - 1), bigger_size)
end

def make_heap(array, first, last)
  size = last - first
  return if size < 2
  small_poplar_size = 15
  if size <= small_poplar_size
    unchecked_insertion_sort(array, first, last)
    return
  end

  poplar_level = 1
  pos = first
  next_ = pos + small_poplar_size
  loop do
    unchecked_insertion_sort(array, pos, next_)
    poplar_size = small_poplar_size
    i = (poplar_level & -poplar_level) >> 1
    while i != 0
      pos -= poplar_size
      poplar_size = 2 * poplar_size + 1
      break if pos + poplar_size > last
      poplar_sift(array, pos, poplar_size)
      next_ += 1
      i >>= 1
    end
    if (last - next_) <= small_poplar_size
      insertion_sort(array, next_, last)
      return
    end
    pos = next_
    next_ += small_poplar_size
    poplar_level += 1
  end
end

def sort_heap(array, first, last_in)
  last = last_in
  size = last - first
  return if size < 2
  loop do
    pop_heap_with_size(array, first, last, size)
    last -= 1
    size -= 1
    break if size <= 1
  end
end

def sort(array)
  n = array.length
  return if n <= 1
  make_heap(array, 0, n)
  sort_heap(array, 0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts "[#{array.join(", ")}]"
