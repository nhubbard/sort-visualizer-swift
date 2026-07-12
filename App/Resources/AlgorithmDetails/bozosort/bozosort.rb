def sorted?(arr)
  (1...arr.length).all? { |i| arr[i - 1] <= arr[i] }
end

def sort(arr)
  n = arr.length
  until sorted?(arr)
    i = rand(n)
    j = rand(n)
    arr[i], arr[j] = arr[j], arr[i]
  end
  arr
end

array = [0, 39, 21, 62, 91, 77]
array = sort(array)
p array
