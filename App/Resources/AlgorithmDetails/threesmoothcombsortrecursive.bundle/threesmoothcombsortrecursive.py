def power_of_three(arr, pos, gap, end):
  if pos + gap > end:
    return

  power_of_three(arr, pos, gap * 3, end)
  power_of_three(arr, pos + gap, gap * 3, end)
  power_of_three(arr, pos + 2 * gap, gap * 3, end)

  i = pos
  while i + gap < end:
    if arr[i] > arr[i + gap]:
      arr[i], arr[i + gap] = arr[i + gap], arr[i]
    i += gap

def recursive_comb(arr, pos, gap, end):
  if pos + gap > end:
    return

  recursive_comb(arr, pos, gap * 2, end)
  recursive_comb(arr, pos + gap, gap * 2, end)

  power_of_three(arr, pos, gap, end)

def sort(arr):
  n = len(arr)
  if n > 1:
    recursive_comb(arr, 0, 1, n)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
