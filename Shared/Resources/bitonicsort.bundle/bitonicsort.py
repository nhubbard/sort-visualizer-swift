def sort(arr):
  n = len(arr)
  for k in range(2, n + 1):
    j = k // 2
    while j > 0:
      for i in range(0, n):
        l = i ^ j
        if l > i:
          if (((i & k) == 0) and (arr[i] > arr[l]) or
             (((i & k) != 0) and (arr[i] < arr[l]))):
            arr[i], arr[l] = arr[l], arr[i]
      j //= 2

if __name__ == "__main__":
  # Specific to bitonic sort: size must be power of 2.
  array = [35, 74, 71, 72, 30, 53, 9, 0]
  sort(array)
  print(array)
