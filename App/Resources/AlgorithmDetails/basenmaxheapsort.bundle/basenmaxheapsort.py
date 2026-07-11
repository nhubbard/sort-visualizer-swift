BASE = 4

def sift_down(arr, node, stop):
  left = node * BASE + 1
  if left >= stop:
    return
  max_index = left
  i = left + 1
  while i < left + BASE and i < stop:
    if arr[max_index] < arr[i]:
      max_index = i
    i += 1
  if arr[node] < arr[max_index]:
    arr[node], arr[max_index] = arr[max_index], arr[node]
    sift_down(arr, max_index, stop)

def sort(arr):
  n = len(arr)
  for i in range(n - 1, -1, -1):
    sift_down(arr, i, n)
  for end in range(n - 1, 0, -1):
    arr[0], arr[end] = arr[end], arr[0]
    sift_down(arr, 0, end)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
