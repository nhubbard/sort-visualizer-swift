def sort(array)
  sorted = false
  until sorted
    # rubocop:disable Lint/UselessAssignment -- read by `until sorted` on the next iteration;
    # rubocop's liveness analysis doesn't track loop-condition variables reassigned in the body.
    sorted = true
    # rubocop:enable Lint/UselessAssignment
    i = 0
    while i < array.length - 1
      if array[i] > array[i + 1]
        array[i], array[i + 1] = array[i + 1], array[i]
        sorted = false
      end
      i += 1
    end
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
