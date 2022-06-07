def selectionSort(arr):
  n = len(arr)
  for i in range(0, n - 1):
    minIdx = i
    for j in range(i + 1, n):
      if arr[j] < arr[minIdx]:
        minIdx = j
    arr[minIdx], arr[i] = arr[i], arr[minIdx]

if __name__ == "__main__":
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  selectionSort(array)
  print(array)