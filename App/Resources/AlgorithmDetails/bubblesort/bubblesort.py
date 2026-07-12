def sort(arr):
  n = len(arr)
  for c in range(0, n - 1):
    for d in range(0, n - c - 1):
      if arr[d] > arr[d + 1]:
        arr[d], arr[d + 1] = arr[d + 1], arr[d]

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)