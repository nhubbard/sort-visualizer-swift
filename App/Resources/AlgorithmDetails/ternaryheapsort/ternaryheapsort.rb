def sort(arr)
  n = arr.length()
  heap_size = n - 1

  max_heapify = lambda do |i|
    left, mid, right = 3 * i + 1, 3 * i + 2, 3 * i + 3
    largest = i
    if left <= heap_size && arr[left] > arr[largest]
      largest = left
    end
    if right <= heap_size && arr[right] > arr[largest]
      largest = right
    end
    if mid <= heap_size && arr[mid] > arr[largest]
      largest = mid
    end
    if largest != i
      arr[i], arr[largest] = arr[largest], arr[i]
      max_heapify.call(largest)
    end
  end

  (n - 1).downto(0) do |i|
    max_heapify.call(i)
  end

  (n - 1).downto(0) do |i|
    arr[0], arr[i] = arr[i], arr[0]
    heap_size -= 1
    max_heapify.call(0)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
