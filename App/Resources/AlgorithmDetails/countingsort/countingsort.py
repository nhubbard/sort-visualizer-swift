def sort(arr):
  n = len(arr)
  if n == 0:
    return arr
  max_value = max(arr)

  counts = [0] * (max_value + 1)
  for value in arr:
    counts[value] += 1
  for i in range(1, max_value + 1):
    counts[i] += counts[i - 1]

  output = [0] * n
  for i in range(n - 1, -1, -1):
    counts[arr[i]] -= 1
    output[counts[arr[i]]] = arr[i]

  for i in range(n):
    arr[i] = output[i]
  return arr

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
