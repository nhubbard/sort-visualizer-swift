def sift_down(arr, root, size)
  index = root
  while 2 * index + 1 < size
    child = 2 * index + 1
    child += 1 if child + 1 < size && arr[child + 1] > arr[child]
    index = child
  end
  root_value = arr[root]
  index = (index - 1) / 2 while root_value > arr[index]
  while index != root
    arr[root], arr[index] = arr[index], arr[root]
    index = (index - 1) / 2
  end
end

def heapify(arr, length)
  ((length - 1) / 2).downto(0) do |i|
    sift_down(arr, i, length)
  end
end

def find_next(arr, size)
  hole = 0
  left = 1
  right = 2
  while right < size && !(arr[left] == -1 && arr[right] == -1)
    if arr[left] == -1
      arr[hole], arr[right] = arr[right], arr[hole]
      hole = right
    elsif arr[right] == -1
      arr[hole], arr[left] = arr[left], arr[hole]
      hole = left
    elsif arr[right] > arr[left]
      arr[hole], arr[right] = arr[right], arr[hole]
      hole = right
    else
      arr[hole], arr[left] = arr[left], arr[hole]
      hole = left
    end
    left = 2 * hole + 1
    right = left + 1
  end
  arr[hole], arr[left] = arr[left], arr[hole] if left < size && arr[left] != -1
end

def sort(arr)
  n = arr.length
  output = Array.new(n, 0)
  if n <= 1
    output[0] = arr[0] if n == 1
    return output
  end
  heapify(arr, n)
  (n - 1).downto(0) do |i|
    output[i] = arr[0]
    arr[0] = -1
    find_next(arr, n)
  end
  output
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
output = sort(array)
puts "[#{output.join(", ")}]"
