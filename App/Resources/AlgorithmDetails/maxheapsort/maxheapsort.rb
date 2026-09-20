def sift_down(arr, root, size)
  loop do
    largest = root
    left = 2 * root + 1
    right = left + 1
    largest = left if left < size && arr[largest] < arr[left]
    largest = right if right < size && arr[largest] < arr[right]
    break if largest == root

    arr[root], arr[largest] = arr[largest], arr[root]
    root = largest
  end
end

def sort(arr)
  n = arr.length
  (n / 2 - 1).downto(0) { |i| sift_down(arr, i, n) }
  (n - 1).downto(1) do |last|
    arr[0], arr[last] = arr[last], arr[0]
    sift_down(arr, 0, last)
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
p sort(array)
