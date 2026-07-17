def sort(arr)
  n = arr.length
  return if n <= 1
  pow2 = (Math.log(n - 1) / Math.log(2)).to_i
  pow2.downto(0) do |k|
    pow3 = ((Math.log(n) - k * Math.log(2)) / Math.log(3)).to_i
    pow3.downto(0) do |j|
      gap = (2.0**k * 3.0**j).to_i
      i = 0
      while i + gap < n
        if arr[i] > arr[i + gap]
          arr[i], arr[i + gap] = arr[i + gap], arr[i]
        end
        i += 1
      end
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
