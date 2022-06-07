def bubbleSort(arr):
  n = len(arr)
  for c in range(0, n - 1):
    for d in range(0, n - c - 1):
      if arr[d] > arr[d + 1]:
        arr[d], arr[d + 1] = arr[d + 1], arr[d]

if __name__ == "__main__":
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  bubbleSort(array)
  print(array)