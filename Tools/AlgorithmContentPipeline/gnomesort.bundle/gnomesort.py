def sort(arr):
  n = len(arr)
  index = 0
  while index < n:
    if index == 0:
      index += 1
    if arr[index] >= arr[index - 1]:
      index += 1
    else:
      arr[index], arr[index - 1] = arr[index - 1], arr[index]
      index -= 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)