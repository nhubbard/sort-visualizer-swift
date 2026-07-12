def sort(arr):
  n = len(arr)
  i = n // 2
  while i > 0:
    for j in range(i, n):
      k = j - i
      while k >= 0:
        if arr[k + i] >= arr[k]:
          break
        else:
          arr[k], arr[k + i] = arr[k + i], arr[k]
        k -= i
    i //= 2

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)