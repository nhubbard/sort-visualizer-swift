import math

def sort(arr):
  n = len(arr)
  if n <= 1:
    return
  pow2 = int(math.log(n - 1) / math.log(2))
  for k in range(pow2, -1, -1):
    pow3 = int((math.log(n) - k * math.log(2)) / math.log(3))
    for j in range(pow3, -1, -1):
      gap = int(math.pow(2, k) * math.pow(3, j))
      i = 0
      while i + gap < n:
        if arr[i] > arr[i + gap]:
          arr[i], arr[i + gap] = arr[i + gap], arr[i]
        i += 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
