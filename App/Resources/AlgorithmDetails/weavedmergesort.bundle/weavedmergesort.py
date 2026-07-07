def merge(arr, tmp, length, residue, modulus):
  if residue + modulus >= length:
    return
  low = residue
  high = residue + modulus
  dmodulus = modulus << 1

  merge(arr, tmp, length, low, dmodulus)
  merge(arr, tmp, length, high, dmodulus)

  nxt = residue
  while low < length and high < length:
    if arr[low] > arr[high] or (arr[low] == arr[high] and low > high):
      tmp[nxt] = arr[high]
      high += dmodulus
    else:
      tmp[nxt] = arr[low]
      low += dmodulus
    nxt += modulus

  if low >= length:
    while high < length:
      tmp[nxt] = arr[high]
      nxt += modulus
      high += dmodulus
  else:
    while low < length:
      tmp[nxt] = arr[low]
      nxt += modulus
      low += dmodulus

  i = residue
  while i < length:
    arr[i] = tmp[i]
    i += modulus

def sort(arr):
  tmp = [0] * len(arr)
  merge(arr, tmp, len(arr), 0, 1)

if __name__ == "__main__":
  array = [0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  print(array)
