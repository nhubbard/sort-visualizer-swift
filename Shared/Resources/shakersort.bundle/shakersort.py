def sort(arr):
  n = len(arr)
  swapped = True
  start = 0
  end = n - 1
  while swapped:
    swapped = False
    for i in range(start, end):
      if arr[i] > arr[i + 1]:
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = True
    if not swapped:
      break
    swapped = False
    end -= 1
    for i in range(end - 1, start - 1, -1):
      if arr[i] > arr[i + 1]:
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = True
    start += 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)