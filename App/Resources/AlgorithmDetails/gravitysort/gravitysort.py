def gravity_sort(arr):
  n = len(arr)
  if n == 0:
    return arr

  min_value = min(arr)
  max_value = max(arr)
  y_size = max_value - min_value + 1

  x = [0] * n
  y = [0] * y_size

  for i in range(n):
    x[i] = arr[i] - min_value
    y[x[i]] += 1

  for i in range(y_size - 1, 0, -1):
    y[i - 1] += y[i]

  for j in range(y_size - 1, -1, -1):
    for i in range(n):
      inc = (1 if i >= n - y[j] else 0) - (1 if x[i] >= j else 0)
      arr[i] += inc

  return arr

def sort(arr):
  return gravity_sort(arr)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
