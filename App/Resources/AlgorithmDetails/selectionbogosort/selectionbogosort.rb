def sort(arr)
  n = arr.length
  (0...n).each do |i|
    while arr[i] != arr[i..-1].min
      j = rand(i..(n - 1))
      arr[i], arr[j] = arr[j], arr[i]
    end
  end
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
