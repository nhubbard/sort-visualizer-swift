def sort(arr)
  n = arr.length
  return if n <= 1

  # Simulate the reporting order that proportional-to-value sleep durations
  # would produce in a jitter-free race: sort by value, ties broken by the
  # original position, i.e. the order the sleeps were originally scheduled.
  woken = arr.each_with_index.sort_by { |value, index| [value, index] }
  n.times { |i| arr[i] = woken[i][0] }

  # Defensive cleanup pass: real scheduling jitter can't be fully trusted,
  # so finish with an ordinary insertion sort no matter what the race produced.
  (1...n).each do |i|
    j = i
    while j > 0 && arr[j - 1] > arr[j]
      arr[j - 1], arr[j] = arr[j], arr[j - 1]
      j -= 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
