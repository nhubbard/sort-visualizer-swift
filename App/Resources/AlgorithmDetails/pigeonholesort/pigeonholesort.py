def sort(arr):
  n = len(arr)
  if n == 0:
    return arr
  min_value = min(arr)
  max_value = max(arr)
  size = max_value - min_value + 1

  holes = [0] * size
  for value in arr:
    holes[value - min_value] += 1

  j = 0
  for count in range(size):
    while holes[count] > 0:
      holes[count] -= 1
      arr[j] = count + min_value
      j += 1
  return arr

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
