def traverse(arr, temp, lower, upper, idx, r)
  traverse(arr, temp, lower, upper, idx, lower[r]) if lower[r] != 0
  temp[idx[0]] = arr[r]
  idx[0] += 1
  traverse(arr, temp, lower, upper, idx, upper[r]) if upper[r] != 0
end

def sort(arr)
  n = arr.length
  return arr if n <= 1

  lower = Array.new(n, 0)
  upper = Array.new(n, 0)

  (1...n).each do |i|
    c = 0
    loop do
      next_arr = arr[i] < arr[c] ? lower : upper
      if next_arr[c] == 0
        next_arr[c] = i
        break
      else
        c = next_arr[c]
      end
    end
  end

  temp = Array.new(n, 0)
  traverse(arr, temp, lower, upper, [0], 0)
  (0...n).each { |i| arr[i] = temp[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
