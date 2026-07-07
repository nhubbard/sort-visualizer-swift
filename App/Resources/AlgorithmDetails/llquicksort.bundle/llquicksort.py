def partition(array, lo, hi):
  pivot = array[hi]
  i = lo
  for j in range(lo, hi):
    if array[j] < pivot:
      array[i], array[j] = array[j], array[i]
      i = i + 1
  array[i], array[hi] = array[hi], array[i]
  return i

def quick_sort(array, lo, hi):
  if lo < hi:
    p = partition(array, lo, hi)
    quick_sort(array, lo, p - 1)
    quick_sort(array, p + 1, hi)

def sort(arr):
  quick_sort(arr, 0, len(arr) - 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
