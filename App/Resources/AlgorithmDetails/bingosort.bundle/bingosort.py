def sort(arr):
  n = len(arr)
  if n < 2:
    return

  # Find the true maximum value in the array.
  maximum = n - 1
  next_value = arr[maximum]
  for i in range(maximum - 1, -1, -1):
    if arr[i] > next_value:
      next_value = arr[i]
  # Skip past any elements already sitting at the tail with that value.
  while maximum > 0 and arr[maximum] == next_value:
    maximum -= 1

  while maximum > 0:
    # This round's target is the max found by the previous pass.
    val = next_value
    next_value = arr[maximum]

    # Sweep once, moving every occurrence of `val` into the shrinking tail
    # while tracking the next-highest value among what's left behind.
    for j in range(maximum - 1, -1, -1):
      if arr[j] == val:
        arr[j], arr[maximum] = arr[maximum], arr[j]
        maximum -= 1
      elif arr[j] > next_value:
        next_value = arr[j]

    while maximum > 0 and arr[maximum] == next_value:
      maximum -= 1

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
