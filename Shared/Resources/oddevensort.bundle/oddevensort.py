def sort(arr):
  sorted = False
  while not sorted:
    sorted = True
    for i in range(1, len(arr) - 1, 2):
      if arr[i] > arr[i + 1]:
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = False
    for i in range(0, len(arr) - 1, 2):
      if arr[i] > arr[i + 1]:
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = False

if __name__ == "__main__":
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  sort(array)
  print(array)
