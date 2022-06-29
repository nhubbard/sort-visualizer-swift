import random

def sort(arr):
  expected = arr[:]
  expected.sort()
  while not (arr == expected):
    random.shuffle(arr)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23]
  sort(array)
  print(array)
