def sift_down(arr, root, size)
  loop do
    smallest = root
    left = 2 * root + 1
    right = 2 * root + 2
    smallest = left if left < size && arr[left] < arr[smallest]
    smallest = right if right < size && arr[right] < arr[smallest]
    break if smallest == root
    arr[root], arr[smallest] = arr[smallest], arr[root]
    root = smallest
  end
end

def heapify(arr)
  (arr.length / 2 - 1).downto(0) do |i|
    sift_down(arr, i, arr.length)
  end
end

def sort(arr)
  heapify(arr)
  (arr.length - 1).downto(1) do |last|
    arr[0], arr[last] = arr[last], arr[0]
    sift_down(arr, 0, last)
  end
  arr.reverse!
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
