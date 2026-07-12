def gapped_insertion_sort(array, a, b, gap):
  i = a + gap
  while i < b:
    key = array[i]
    j = i - gap
    while j >= a and key < array[j]:
      array[j + gap] = array[j]
      j = j - gap
    array[j + gap] = key
    i = i + gap

def recursive_shell_sort(array, start, end, g):
  if start + g <= end:
    recursive_shell_sort(array, start, end, 3 * g)
    recursive_shell_sort(array, start + g, end, 3 * g)
    recursive_shell_sort(array, start + 2 * g, end, 3 * g)
    gapped_insertion_sort(array, start, end, g)

def sort(arr):
  recursive_shell_sort(arr, 0, len(arr), 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
