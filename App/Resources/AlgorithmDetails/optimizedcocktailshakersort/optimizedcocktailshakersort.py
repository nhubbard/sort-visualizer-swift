def sort(arr):
  start = 0
  end = len(arr) - 1
  while start < end:
    consec_sorted = 1
    for i in range(start, end):
      if arr[i] > arr[i + 1]:
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        consec_sorted = 1
      else:
        consec_sorted += 1
    end -= consec_sorted

    consec_sorted = 1
    for j in range(end, start, -1):
      if arr[j - 1] > arr[j]:
        arr[j - 1], arr[j] = arr[j], arr[j - 1]
        consec_sorted = 1
      else:
        consec_sorted += 1
    start += consec_sorted

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
