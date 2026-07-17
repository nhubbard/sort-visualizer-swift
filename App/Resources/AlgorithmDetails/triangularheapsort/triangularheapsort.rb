def triangular_root(val)
  (Math.sqrt(8 * val + 1).to_i - 1) / 2
end

def sift_down(array, root, size)
  loop do
    row = triangular_root(root)
    left = root + row + 1
    break if left >= size
    right = left + 1
    largest = root
    largest = left if array[largest] < array[left]
    largest = right if right < size && array[largest] < array[right]
    break if largest == root
    array[root], array[largest] = array[largest], array[root]
    root = largest
  end
end

def heapify(array, length)
  (length - 1).downto(0) do |i|
    sift_down(array, i, length)
  end
end

def sort(array)
  n = array.length
  return if n <= 1
  heapify(array, n)
  (1...n - 1).each do |i|
    array[0], array[n - i] = array[n - i], array[0]
    sift_down(array, 0, n - i)
  end
  array[0], array[1] = array[1], array[0] if array[0] > array[1]
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts "[#{array.join(", ")}]"
