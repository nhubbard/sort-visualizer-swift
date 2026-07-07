def sort(arr):
  n = len(arr)
  if n < 2:
    return

  threshold = 32

  def insertion_sort(start, end):
    for i in range(start + 1, end):
      j = i
      while j > start and arr[j] < arr[j - 1]:
        arr[j - 1], arr[j] = arr[j], arr[j - 1]
        j -= 1

  def merge(start, mid, end):
    low = start
    high = mid
    merged = []
    while low < mid and high < end:
      if arr[high] < arr[low]:
        merged.append(arr[high])
        high += 1
      else:
        merged.append(arr[low])
        low += 1
    while low < mid:
      merged.append(arr[low])
      low += 1
    while high < end:
      merged.append(arr[high])
      high += 1
    for i in range(len(merged)):
      arr[start + i] = merged[i]

  def merge_sort(start, end):
    if end - start <= threshold:
      insertion_sort(start, end)
      return
    mid = start + (end - start) // 2
    merge_sort(start, mid)
    merge_sort(mid, end)
    merge(start, mid, end)

  merge_sort(0, n)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
