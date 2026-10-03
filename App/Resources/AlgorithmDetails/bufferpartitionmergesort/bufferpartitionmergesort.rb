def sort(arr)
  run = 8
  (0...arr.length).step(run) do |start|
    finish = [start + run, arr.length].min
    (start + 1...finish).each do |i|
      value = arr[i]
      j = i
      while j > start && arr[j - 1] > value
        arr[j] = arr[j - 1]
        j -= 1
      end
      arr[j] = value
    end
  end

  scratch = arr.dup
  width = run
  while width < arr.length
    (0...arr.length).step(2 * width) do |start|
      middle = [start + width, arr.length].min
      finish = [start + 2 * width, arr.length].min
      left = start
      right = middle
      (start...finish).each do |out|
        if left < middle && (right >= finish || arr[left] < arr[right])
          scratch[out] = arr[left]
          left += 1
        else
          scratch[out] = arr[right]
          right += 1
        end
      end
    end
    arr.replace(scratch)
    width *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
