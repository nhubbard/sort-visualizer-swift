def sort(arr):
  n = len(arr)
  k = 2
  while k <= n:
    j = k // 2
    while j > 0:
      i = 0
      while i < n:
        l = i ^ j
        if l > i:
          if (
            ((i & k) == 0) and (arr[i] > arr[l])
            or (((i & k) != 0) and (arr[i] < arr[l]))
          ):
            arr[i], arr[l] = arr[l], arr[i]
        i += 1
      j //= 2
    k *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)