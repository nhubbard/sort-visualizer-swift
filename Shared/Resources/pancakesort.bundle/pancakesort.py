def flip(arr, n):
  left = 0
  while left < n:
    arr[left], arr[n] = arr[n], arr[left]
    n -= 1
    left += 1

def max_index(arr, n):
  index = 0
  for i in range(n):
    if arr[i] > arr[index]:
      index = i
  return index
  
def sort(arr):
  n = len(arr)
  while n > 1:
    max = max_index(arr, n)
    if max != n:
      flip(arr, max)
      flip(arr, n - 1)
    n -= 1

if __name__ == "__main__":
  array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
  sort(array)
  print(array)
