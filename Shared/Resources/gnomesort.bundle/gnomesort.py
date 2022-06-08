def gnomeSort(arr):
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
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  gnomeSort(array)
  print(array)