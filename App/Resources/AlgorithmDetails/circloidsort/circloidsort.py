def circle(array, left, right):
  a = left
  b = right
  swapped = False
  while a < b:
    if array[a] > array[b]:
      array[a], array[b] = array[b], array[a]
      swapped = True
    a += 1
    b -= 1
    if a == b:
      b += 1
  return swapped

def circle_pass(array, left, right):
  if left >= right:
    return False
  mid = (left + right) // 2
  l = circle_pass(array, left, mid)
  r = circle_pass(array, mid + 1, right)
  return circle(array, left, right) or l or r

def sort(arr):
  n = len(arr)
  if n <= 1:
    return
  while circle_pass(arr, 0, n - 1):
    pass

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
