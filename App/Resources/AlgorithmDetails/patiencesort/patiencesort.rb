class MinHeap
  def initialize
    @storage = []
  end

  def empty?
    @storage.empty?
  end

  def push(entry)
    @storage.push(entry)
    i = @storage.length - 1
    while i > 0
      parent = (i - 1) / 2
      break if @storage[parent][0] <= @storage[i][0]

      @storage[parent], @storage[i] = @storage[i], @storage[parent]
      i = parent
    end
  end

  def pop_min
    result = @storage[0]
    last = @storage.pop
    unless @storage.empty?
      @storage[0] = last
      i = 0
      loop do
        left = (2 * i) + 1
        right = (2 * i) + 2
        smallest = i
        smallest = left if left < @storage.length && @storage[left][0] < @storage[smallest][0]
        smallest = right if right < @storage.length && @storage[right][0] < @storage[smallest][0]
        break if smallest == i

        @storage[i], @storage[smallest] = @storage[smallest], @storage[i]
        i = smallest
      end
    end
    result
  end
end

def sort(arr)
  n = arr.length
  piles = []
  tops = []

  arr.each do |x|
    # binary search: leftmost pile whose top is >= x
    lo = 0
    hi = piles.length
    while lo < hi
      mid = (lo + hi) / 2
      if tops[mid] >= x
        hi = mid
      else
        lo = mid + 1
      end
    end
    if lo == piles.length
      piles.push([x])
      tops.push(x)
    else
      piles[lo].push(x)
      tops[lo] = x
    end
  end

  heap = MinHeap.new
  piles.each_index do |i|
    heap.push([tops[i], i])
  end

  result = []
  until heap.empty?
    _top_value, pile_index = heap.pop_min
    value = piles[pile_index].pop
    result.push(value)
    heap.push([piles[pile_index].last, pile_index]) unless piles[pile_index].empty?
  end

  (0...n).each do |i|
    arr[i] = result[i]
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
