def sort(arr):
  for i in range(1, len(arr)):
    pos = i
    while pos > 0 and arr[pos - 1] > arr[pos]:
      arr[pos - 1], arr[pos] = arr[pos], arr[pos - 1]
      pos -= 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
