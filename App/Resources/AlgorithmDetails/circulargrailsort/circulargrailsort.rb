def sort(array)
  count = array.length
  return if count < 2

  swap = lambda do |a, b|
    a %= count
    b %= count
    array[a], array[b] = array[b], array[a]
  end
  shift_forward = lambda do |a, middle, finish|
    while middle < finish
      swap.call(a, middle)
      a += 1
      middle += 1
    end
  end
  shift_backward = lambda do |start, middle, finish|
    while middle > start
      finish -= 1
      middle -= 1
      swap.call(finish, middle)
    end
  end
  insertion = lambda do |start, finish|
    (start + 1...finish).each do |first|
      i = first
      while i > start && array[(i - 1) % count] > array[i % count]
        swap.call(i, i - 1)
        i -= 1
      end
    end
  end
  multi_swap = lambda do |a, b, length|
    length.times { |i| swap.call(a + i, b + i) }
  end
  rotate = lambda do |start, middle, finish|
    left = middle - start
    right = finish - middle
    while left.positive? && right.positive?
      if right < left
        multi_swap.call(middle - right, middle, right)
        finish -= right
        middle -= right
        left -= right
      else
        multi_swap.call(start, middle, left)
        start += left
        middle += left
        right -= left
      end
    end
  end
  in_place_merge = lambda do |start, middle, finish|
    i = start
    while i < middle && middle < finish
      if array[i % count] > array[middle % count]
        k = middle + 1
        k += 1 while k < finish && array[i % count] > array[k % count]
        rotate.call(i, middle, k)
        i += k - middle
        middle = k
      else
        i += 1
      end
    end
  end
  merge = lambda do |position, start, middle, finish, full|
    i = start
    j = middle
    while i < middle && j < finish
      if array[i % count] <= array[j % count]
        swap.call(position, i)
        i += 1
      else
        swap.call(position, j)
        j += 1
      end
      position += 1
    end
    if i < middle
      shift_forward.call(position, i, middle) if i > position
    elsif full
      shift_forward.call(position, j, finish)
    end
    (i < middle) ? i : j
  end
  block_less = lambda do |a, b, length|
    next array[a % count] < array[b % count] if array[a % count] != array[b % count]

    array[(a + length - 1) % count] < array[(b + length - 1) % count]
  end
  block_merge = lambda do |start, middle, finish, length|
    b1 = finish - (finish - middle - 1) % length - 1
    if b1 <= middle
      merge.call(start - length, start, middle, finish, true)
      next
    end
    b2 = b1
    i = middle - length
    while i > start && block_less.call(b1, i, length)
      i -= length
      b2 -= length
    end
    (start...b1 - length).step(length) do |j|
      minimum = j
      (j + length...b1).step(length) do |candidate|
        minimum = candidate if block_less.call(candidate, minimum, length)
      end
      multi_swap.call(j, minimum, length) if minimum != j
    end
    frontier = start
    (start + length...b2).step(length) do |nxt|
      frontier = merge.call(frontier - length, frontier, nxt, nxt + length, false)
      if frontier < nxt
        shift_backward.call(frontier, nxt, nxt + length)
        frontier += length
      end
    end
    merge.call(frontier - length, frontier, b1, finish, true)
  end

  if count <= 16
    insertion.call(0, count)
    return
  end
  block = 1
  block *= 2 while block * block < count
  i = block
  run = 1
  rolling = count - block
  finish = count
  while run <= block
    while i + 2 * run < finish
      merge.call(i - run, i, i + run, i + 2 * run, true)
      i += 2 * run
    end
    if i + run < finish
      merge.call(i - run, i, i + run, finish, true)
    else
      shift_forward.call(i - run, i, finish)
    end
    i = finish + block - run
    finish = i + rolling
    run *= 2
  end
  while run < rolling
    while i + 2 * run < finish
      block_merge.call(i, i + run, i + 2 * run, block)
      i += 2 * run
    end
    if i + run < finish
      block_merge.call(i, i + run, finish, block)
    else
      shift_forward.call(i - block, i, finish)
    end
    i = finish
    finish += rolling
    run *= 2
  end
  insertion.call(i - block, i)
  in_place_merge.call(i - block, i, finish)
  rotate.call(0, (i - block) % count, count)
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
