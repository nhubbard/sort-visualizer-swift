def flip(arr, end):
  start = 0
  while start < end:
    arr[start], arr[end] = arr[end], arr[start]
    start += 1
    end -= 1

def sort(arr):
  n = len(arr)
  for i in range(n - 1, 0, -1):
    max_index = 0
    for j in range(max_index + 1, i + 1):
      if arr[j] > arr[max_index]:
        max_index = j
    if max_index != i:
      flip(arr, max_index)
      flip(arr, i)
      flip(arr, i - 1)
      flip(arr, max_index - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)