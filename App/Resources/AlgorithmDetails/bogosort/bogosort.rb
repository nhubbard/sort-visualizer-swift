def sort(a)
  n = a.length
  return a if n < 2 || (1...n).all? { |i| a[i] >= a[i - 1] }
  reverse = lambda do |low, high|
    while low < high
      a[low], a[high] = a[high], a[low]
      low += 1
      high -= 1
    end
  end
  loop do
    pivot = n - 2
    pivot -= 1 while pivot >= 0 && a[pivot] >= a[pivot + 1]
    break if pivot < 0
    successor = n - 1
    successor -= 1 while a[successor] <= a[pivot]
    a[pivot], a[successor] = a[successor], a[pivot]
    reverse.call(pivot + 1, n - 1)
  end
  reverse.call(0, n - 1)
  a
end
array = [0, 39, 21, 62, 91, 77, 14, 23]
puts sort(array).inspect
