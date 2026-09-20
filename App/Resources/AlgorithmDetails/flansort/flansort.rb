class Flan
  GAP = 14
  RATIO = 4
  MASK = (1 << 64) - 1

  def initialize(values)
    @a = values
    @position = Array.new(GAP + 2, 0)
    @heap = Array.new(GAP + 2, 0)
    @state = 0x9e3779b97f4a7c15
    @a.each do |value|
      @state = ((@state ^ (value & MASK)) * 0xbf58476d1ce4e5b9 + 0x94d049bb133111eb) & MASK
    end
  end

  def choice(count)
    @state ^= @state >> 12
    @state ^= (@state << 25) & MASK
    @state ^= @state >> 27
    ((@state * 0x2545f4914f6cdd1d) & MASK) % count
  end

  def swap(i, j)
    @a[i], @a[j] = @a[j], @a[i]
  end

  def median(i, m, j)
    if @a[m] > @a[i]
      return m if @a[m] < @a[j]
      return (@a[i] > @a[j]) ? i : j
    end
    return m if @a[m] > @a[j]
    (@a[i] < @a[j]) ? i : j
  end

  def ninther(first, last)
    step = (last - first) / 9
    median(median(first, first + step, first + 2 * step),
      median(first + 3 * step, first + 4 * step, first + 5 * step),
      median(first + 6 * step, first + 7 * step, first + 8 * step))
  end

  def pivot(first, last)
    step = (last - first) / 3
    median(ninther(first, first + step), ninther(first + step, first + 2 * step), ninther(first + 2 * step, last))
  end

  def binary_search(first, last, value, backward)
    while first < last
      middle = first + (last - first) / 2
      found = backward ? @a[middle] < value : @a[middle] > value
      found ? last = middle : first = middle + 1
    end
    first
  end

  def insert(value, from, to)
    while from > to
      from -= 1
      @a[from + 1] = @a[from]
    end
    @a[to] = value
  end

  def insertion(first, last)
    (first + 1...last).each do |i|
      value = @a[i]
      insert(value, i, binary_search(first, i, value, false))
    end
  end

  def block_search(first, last, value, right)
    while first < last
      middle = first + ((last - first) / (GAP + 1) / 2) * (GAP + 1)
      found = right ? @a[middle] > value : @a[middle] >= value
      found ? last = middle : first = middle + GAP + 1
    end
    first
  end

  def retrieve(finish, scratch, p_end, boundary, backward)
    destination = finish - 1
    block = p_end - (GAP + 1)
    while block > scratch + GAP
      item = binary_search(block - GAP, block, boundary, backward) - 1
      block -= GAP + 1
      while item >= block
        swap(destination, item)
        destination -= 1
        item -= 1
      end
    end
    item = binary_search(scratch, scratch + GAP, boundary, backward) - 1
    while item >= scratch
      swap(destination, item)
      destination -= 1
      item -= 1
    end
  end

  def library_sort(first, last, scratch, boundary, backward)
    length = last - first
    if length < 32
      insertion(first, last)
      return
    end
    count = length
    count = (count - 1) / RATIO + 1 while count >= 32
    i = first + count
    trigger = first + RATIO * count
    p_end = scratch + (count + 1) * (GAP + 1) + GAP
    insertion(first, i)
    count.times { |k| swap(first + k, scratch + k * (GAP + 1) + GAP) }
    while i < last
      if i == trigger
        retrieve(i, scratch, p_end, boundary, backward)
        count = i - first
        p_end = scratch + (count + 1) * (GAP + 1) + GAP
        trigger = first + (trigger - first) * RATIO
        count.times { |k| swap(first + k, scratch + k * (GAP + 1) + GAP) }
      end
      value = @a[i]
      block = block_search(scratch + GAP, p_end - (GAP + 1), value, false)
      if @a[block] == value
        after_equal = block_search(block + GAP + 1, p_end - (GAP + 1), value, true)
        block += choice((after_equal - block) / (GAP + 1)) * (GAP + 1)
      end
      loc = binary_search(block - GAP, block, boundary, backward)
      if loc == block
        loop do
          block += GAP + 1
          break if block >= p_end || binary_search(block - GAP, block, boundary, backward) != block
        end
        if block == p_end
          retrieve(i, scratch, p_end, boundary, backward)
          count = i - first
          p_end = scratch + (count + 1) * (GAP + 1) + GAP
          trigger = first + (trigger - first) * RATIO
          count.times { |k| swap(first + k, scratch + k * (GAP + 1) + GAP) }
        else
          first_item = binary_search(block - GAP, block, boundary, backward)
          distance = block - [first_item, block - GAP / 2].max
          source = block - distance
          destination = block
          while source > loc - distance
            source -= 1
            destination -= 1
            swap(destination, source)
          end
        end
      else
        displaced = @a[loc]
        @a[i] = displaced
        i += 1
        insert(value, loc, binary_search(block - GAP, loc, value, false))
      end
    end
    retrieve(last, scratch, p_end, boundary, backward)
  end

  def less(x, y)
    left, right = @a[@position[x]], @a[@position[y]]
    left < right || (left == right && x < y)
  end

  def sift(item, first, size)
    root = first
    while 2 * root + 2 < size
      left = 2 * root + 1
      child = less(@heap[left], @heap[left + 1]) ? left : left + 1
      break unless less(@heap[child], item)
      @heap[root] = @heap[child]
      root = child
    end
    left = 2 * root + 1
    if left < size && less(@heap[left], item)
      @heap[root] = @heap[left]
      root = left
    end
    @heap[root] = item
  end

  def merge(run_length, finish, destination, count)
    if count < 2
      if count == 1
        while @position[0] < finish
          swap(destination, @position[0])
          destination += 1
          @position[0] += 1
        end
      end
      return
    end
    first = @position[0]
    count.times { |i| @heap[i] = i }
    ((count - 1) / 2).downto(0) { |i| sift(@heap[i], i, count) }
    size = count
    while size > 0
      run = @heap[0]
      swap(destination, @position[run])
      destination += 1
      @position[run] += 1
      if @position[run] == [first + (run + 1) * run_length, finish].min
        size -= 1
        sift(@heap[size], 0, size)
      else
        sift(@heap[0], 0, size)
      end
    end
  end

  def execute
    first, finish = 0, @a.length
    while finish - first >= 32
      pivot_value = @a[pivot(first, finish)]
      before, i, j, after = first, first - 1, finish, finish
      loop do
        i += 1
        while i < j
          if @a[i] == pivot_value
            swap(before, i)
            before += 1
          elsif @a[i] < pivot_value
            break
          end
          i += 1
        end
        j -= 1
        while j > i
          if @a[j] == pivot_value
            after -= 1
            swap(after, j)
          elsif @a[j] > pivot_value
            break
          end
          j -= 1
        end
        if i < j
          swap(i, j)
        else
          return @a if before == finish
          j += 1 if j < i
          while before > first
            i -= 1
            before -= 1
            swap(i, before)
          end
          while after < finish
            swap(j, after)
            j += 1
            after += 1
          end
          break
        end
      end
      left, right, count = i - first, finish - j, 0
      if left <= right
        move = finish - left
        left = [(right + 1) / (GAP + 1), 16].max
        k = first
        while k < i
          library_sort(k, [k + left, i].min, j, pivot_value, true)
          @position[count] = k
          count += 1
          k += left
        end
        merge(left, i, move, count)
        if j - i < move - j
          while i < j
            move -= 1
            swap(i, move)
            i += 1
          end
          finish = move
        else
          while move > j
            move -= 1
            swap(i, move)
            i += 1
          end
          finish = i
        end
      else
        move = first + right
        right = [(left + 1) / (GAP + 1), 16].max
        k = j
        while k < finish
          library_sort(k, [k + right, finish].min, first, pivot_value, false)
          @position[count] = k
          count += 1
          k += right
        end
        merge(right, finish, first, count)
        if i - move < j - i
          while move < i
            j -= 1
            swap(move, j)
            move += 1
          end
          first = j
        else
          while j > i
            j -= 1
            swap(move, j)
            move += 1
          end
          first = move
        end
      end
    end
    insertion(first, finish)
    @a
  end
end

def sort(a)
  Flan.new(a).execute
end
array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
puts sort(array).inspect
