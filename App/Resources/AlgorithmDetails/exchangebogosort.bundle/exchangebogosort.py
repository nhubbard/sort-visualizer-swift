import random

def is_sorted(arr):
  return all(arr[i - 1] <= arr[i] for i in range(1, len(arr)))

def sort(arr):
  n = len(arr)
  while not is_sorted(arr):
    i = random.randrange(n)
    j = random.randrange(n)
    if (i < j and arr[i] > arr[j]) or (i > j and arr[i] < arr[j]):
      arr[i], arr[j] = arr[j], arr[i]

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23]
  sort(array)
  print(array)
