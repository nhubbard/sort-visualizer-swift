BASE = 4

def sift_down(arr, node, stop)
  left = node * BASE + 1
  return if left >= stop
  max_index = left
  i = left + 1
  while i < left + BASE && i < stop
    max_index = i if arr[max_index] < arr[i]
    i += 1
  end
  if arr[node] < arr[max_index]
    arr[node], arr[max_index] = arr[max_index], arr[node]
    sift_down(arr, max_index, stop)
  end
end

def sort(arr)
  n = arr.length
  (n - 1).downto(0) do |i|
    sift_down(arr, i, n)
  end
  (n - 1).downto(1) do |end_index|
    arr[0], arr[end_index] = arr[end_index], arr[0]
    sift_down(arr, 0, end_index)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
