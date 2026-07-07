def destination(array, flagged, a, b1, b):
  held_value = array[a]
  d = a
  e = 0
  for i in range(a + 1, b):
    if array[i] < held_value:
      d += 1
    elif i < b1 and not flagged[i] and array[i] == held_value:
      e += 1
  while flagged[d] or e > 0:
    if not flagged[d]:
      e -= 1
    d += 1
  return d

def stable_cycle_sort(array):
  n = len(array)
  if n <= 1:
    return array
  flagged = [False] * n
  for i in range(n - 1):
    if flagged[i]:
      continue
    j = i
    while True:
      k = destination(array, flagged, i, j, n)
      array[i], array[k] = array[k], array[i]
      flagged[k] = True
      j = k
      if j == i:
        break
  return array

def sort(array):
  return stable_cycle_sort(array)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
