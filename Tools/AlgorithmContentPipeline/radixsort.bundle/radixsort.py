def counting(arr, e):
  n = len(arr)
  output = [0] * n
  count = [0] * (10)
  for i in range(0, n):
    index = (arr[i] / e)
    count[int(index % 10)] += 1
  for i in range(1, 10):
    count[i] += count[i - 1]
  i = n - 1
  while i >= 0:
    index = arr[i] / e
    output[count[int(index % 10)] - 1] = arr[i]
    count[int(index % 10)] -= 1
    i -= 1
  i = 0
  for i in range(0, len(arr)):
    arr[i] = output[i]

def sort(arr):
  x = max(arr)
  e = 1
  while x / e > 0:
    counting(arr, e)
    e *= 10

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)