def sort(arr):
  n = len(arr)
  for start in range(1, n):
    i = start
    k = start - 1
    while k >= 0:
      if arr[i] < arr[k]:
        arr[i], arr[k] = arr[k], arr[i]
      k -= 1
      i -= 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)