def sort(arr)
  n = arr.length()
  return if n < 2

  # Find the true maximum value in the array.
  maximum = n - 1
  next_value = arr[maximum]
  (maximum - 1).downto(0) do |i|
    next_value = arr[i] if arr[i] > next_value
  end
  # Skip past any elements already sitting at the tail with that value.
  while maximum > 0 && arr[maximum] == next_value
    maximum -= 1
  end

  while maximum > 0
    # This round's target is the max found by the previous pass.
    val = next_value
    next_value = arr[maximum]

    # Sweep once, moving every occurrence of `val` into the shrinking tail
    # while tracking the next-highest value among what's left behind.
    (maximum - 1).downto(0) do |j|
      if arr[j] == val
        arr[j], arr[maximum] = arr[maximum], arr[j]
        maximum -= 1
      elsif arr[j] > next_value
        next_value = arr[j]
      end
    end

    while maximum > 0 && arr[maximum] == next_value
      maximum -= 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
