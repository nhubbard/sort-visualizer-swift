def reverse_range(arr, lo, hi)
  while lo < hi
    arr[lo], arr[hi] = arr[hi], arr[lo]
    lo += 1
    hi -= 1
  end
end

def twin_swap(arr, nmemb)
  index = 0
  endpos = nmemb - 2
  while index <= endpos
    if arr[index] <= arr[index + 1]
      index += 2
      next
    end
    start = index
    index += 2
    loop do
      if index > endpos
        if start == 0 && (nmemb.even? || arr[index - 1] > arr[index])
          endpos = nmemb - 1
          reverse_range(arr, start, endpos)
          return 1
        end
        break
      end
      if arr[index] > arr[index + 1]
        if arr[index - 1] > arr[index]
          index += 2
          next
        end
        arr[index], arr[index + 1] = arr[index + 1], arr[index]
      end
      break
    end
    endpos = index - 1
    reverse_range(arr, start, endpos)
    endpos = nmemb - 2
    index += 2
  end
  0
end

def tail_merge(arr, buf, nmemb, block)
  s = 0
  while block < nmemb
    offset = 0
    while offset + block < nmemb
      a = offset
      e = a + block - 1
      if arr[e] <= arr[e + 1]
        offset += block * 2
        next
      end
      if offset + block * 2 <= nmemb
        c_max = s + block
        d_max = a + block * 2
      else
        c_max = s + nmemb - (offset + block)
        d_max = nmemb
      end
      d = d_max - 1
      while arr[e] <= arr[d]
        d_max -= 1
        d -= 1
        c_max -= 1
      end
      c = s
      d = a + block
      while c < c_max
        buf[c] = arr[d]
        c += 1
        d += 1
      end
      c -= 1
      d = a + block - 1
      e = d_max - 1
      if arr[a] <= arr[a + block]
        arr[e] = arr[d]
        e -= 1
        d -= 1
        while c >= s
          while arr[d] > buf[c]
            arr[e] = arr[d]
            e -= 1
            d -= 1
          end
          arr[e] = buf[c]
          e -= 1
          c -= 1
        end
      else
        arr[e] = arr[d]
        e -= 1
        d -= 1
        while d >= a
          while arr[d] <= buf[c]
            arr[e] = buf[c]
            e -= 1
            c -= 1
          end
          arr[e] = arr[d]
          e -= 1
          d -= 1
        end
        while c >= s
          arr[e] = buf[c]
          e -= 1
          c -= 1
        end
      end
      offset += block * 2
    end
    block *= 2
  end
end

def twinsort(arr, nmemb)
  if twin_swap(arr, nmemb) == 0
    buf = Array.new(nmemb / 2, 0)
    tail_merge(arr, buf, nmemb, 2)
  end
end

def sort(arr)
  n = arr.length
  twinsort(arr, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
