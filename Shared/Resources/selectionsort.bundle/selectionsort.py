def sort(arr):
  n = len(arr)
  for i in range(0, n - 1):
    minIdx = i
    for j in range(i + 1, n):
      if arr[j] < arr[minIdx]:
        minIdx = j
    arr[minIdx], arr[i] = arr[i], arr[minIdx]

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)