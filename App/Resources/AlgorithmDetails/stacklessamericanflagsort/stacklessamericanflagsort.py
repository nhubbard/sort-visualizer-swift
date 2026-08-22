RADIX = 4


def get_digit(value, place):
    for _ in range(place):
        value //= RADIX
    return value % RADIX


def shift(value, places):
    for _ in range(places):
        value //= RADIX
    return value


def sort(arr):
    n = len(arr)
    if n < 2:
        return

    q = 0
    probe = RADIX
    max_value = max(arr)
    while probe <= max_value:
        q += 1
        probe *= RADIX

    counts = [0] * RADIX
    offsets = [0] * RADIX

    def bump(digit):
        counts[digit] += 1

    def distribute(start, end, place):
        # Turn the raw per-bucket counts already accumulated in `counts` into
        # starting offsets, then place every element in [start, end) by
        # following displacement cycles, one bucket at a time.
        for i in range(1, RADIX):
            counts[i] += counts[i - 1]
            offsets[i] = counts[i - 1]

        for bucket in range(RADIX - 1):
            position = start + offsets[bucket]
            if counts[bucket] > offsets[bucket]:
                held = arr[position]
                while True:
                    digit = get_digit(held, place)
                    counts[digit] -= 1
                    displaced = arr[start + counts[digit]]
                    arr[start + counts[digit]] = held
                    held = displaced
                    if counts[bucket] <= offsets[bucket]:
                        break

        split = start + offsets[1]
        for i in range(RADIX):
            counts[i] = 0
            offsets[i] = 0
        return split

    # `i`/`b` track the bounds of whichever range is currently active, `q`
    # the digit place being distributed on, and `m` a counter that mirrors
    # how many bucket boundaries have already been walked at the current
    # depth, standing in for the call stack a recursive walk would need.
    m = 0
    i = 0
    b = n

    for j in range(i, b):
        bump(get_digit(arr[j], q))

    while i < n:
        p = i if b - i < 1 else distribute(i, b, q)

        if q == 0:
            m += RADIX
            t = m // RADIX
            while t % RADIX == 0:
                t //= RADIX
                q += 1

            i = b
            while b < n and shift(arr[b], q + 1) == shift(m, q + 1):
                bump(get_digit(arr[b], q))
                b += 1
        else:
            b = p
            q -= 1
            for j in range(i, b):
                bump(get_digit(arr[j], q))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
