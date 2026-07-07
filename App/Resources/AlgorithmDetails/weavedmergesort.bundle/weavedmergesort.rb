def merge(arr, tmp, length, residue, modulus)
  return if residue + modulus >= length

  low = residue
  high = residue + modulus
  dmodulus = modulus << 1

  merge(arr, tmp, length, low, dmodulus)
  merge(arr, tmp, length, high, dmodulus)

  nxt = residue
  while low < length && high < length
    if arr[low] > arr[high] || (arr[low] == arr[high] && low > high)
      tmp[nxt] = arr[high]
      high += dmodulus
    else
      tmp[nxt] = arr[low]
      low += dmodulus
    end
    nxt += modulus
  end

  if low >= length
    while high < length
      tmp[nxt] = arr[high]
      nxt += modulus
      high += dmodulus
    end
  else
    while low < length
      tmp[nxt] = arr[low]
      nxt += modulus
      low += dmodulus
    end
  end

  i = residue
  while i < length
    arr[i] = tmp[i]
    i += modulus
  end
end

def sort(arr)
  tmp = Array.new(arr.length, 0)
  merge(arr, tmp, arr.length, 0, 1)
  return arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
