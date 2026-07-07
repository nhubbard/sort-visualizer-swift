def sort(arr):
  n = len(arr)
  shrink = 1.3
  gap = n
  sorted = False
  while not sorted:
    gap = int(gap / shrink)
    if gap <= 1:
      sorted = True
      gap = 1
    for i in range(n - gap):
      sm = gap + i
      if arr[i] > arr[sm]:
        arr[i], arr[sm] = arr[sm], arr[i]
        sorted = False

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
