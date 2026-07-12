import random

def is_minimum(arr, start, end):
  for k in range(start + 1, end):
    if arr[start] > arr[k]:
      return False
  return True

def is_maximum(arr, start, end):
  for k in range(start, end - 1):
    if arr[k] > arr[end - 1]:
      return False
  return True

def shuffle_range(arr, start, end):
  for i in range(start, end - 1):
    j = random.randint(i, end - 1)
    arr[i], arr[j] = arr[j], arr[i]

def sort(arr):
  lo = 0
  hi = len(arr)
  while lo < hi - 1:
    if is_minimum(arr, lo, hi):
      lo += 1
    elif is_maximum(arr, lo, hi):
      hi -= 1
    else:
      shuffle_range(arr, lo, hi)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23]
  sort(array)
  print(array)
