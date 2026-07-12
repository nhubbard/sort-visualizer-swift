def is_3_smooth(n):
  while n % 6 == 0:
    n //= 6
  while n % 3 == 0:
    n //= 3
  while n % 2 == 0:
    n //= 2
  return n == 1

def sort(array):
  length = len(array)
  for g in range(length - 1, 0, -1):
    if is_3_smooth(g):
      for i in range(g, length):
        if array[i - g] > array[i]:
          array[i - g], array[i] = array[i], array[i - g]
  return array

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
