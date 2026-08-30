def swap2(arr, i, j):
    arr[i], arr[j] = arr[j], arr[i]


def reverse_inclusive(arr, lo, hi):
    while lo < hi:
        swap2(arr, lo, hi)
        lo += 1
        hi -= 1


# -- Fixed-size sorting networks --------------------------------------------------------------


def swap_two(arr, start):
    if arr[start] > arr[start + 1]:
        swap2(arr, start, start + 1)


def swap_three(arr, start):
    if arr[start] > arr[start + 1]:
        if arr[start] <= arr[start + 2]:
            swap2(arr, start, start + 1)
        elif arr[start + 1] > arr[start + 2]:
            swap2(arr, start, start + 2)
        else:
            temp = arr[start]
            arr[start] = arr[start + 1]
            arr[start + 1] = arr[start + 2]
            arr[start + 2] = temp
    elif arr[start + 1] > arr[start + 2]:
        if arr[start] > arr[start + 2]:
            temp = arr[start + 2]
            arr[start + 2] = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = temp
        else:
            swap2(arr, start + 2, start + 1)


def swap_four(arr, start):
    if arr[start] > arr[start + 1]:
        swap2(arr, start, start + 1)
    if arr[start + 2] > arr[start + 3]:
        swap2(arr, start + 2, start + 3)
    if arr[start + 1] > arr[start + 2]:
        if arr[start] <= arr[start + 2]:
            if arr[start + 1] <= arr[start + 3]:
                swap2(arr, start + 1, start + 2)
            else:
                temp = arr[start + 1]
                arr[start + 1] = arr[start + 2]
                arr[start + 2] = arr[start + 3]
                arr[start + 3] = temp
        elif arr[start] > arr[start + 3]:
            swap2(arr, start + 1, start + 3)
            swap2(arr, start, start + 2)
        elif arr[start + 1] <= arr[start + 3]:
            temp = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = arr[start + 2]
            arr[start + 2] = temp
        else:
            temp = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = arr[start + 2]
            arr[start + 2] = arr[start + 3]
            arr[start + 3] = temp


def swap_five(arr, start, end):
    # Inserts the element at `end` into the already-sorted run [start, end - 1] (always exactly
    # 4 elements: swap_four runs immediately before every call site). Returns the new `end`.
    end = start + 4
    pta = end
    end += 1
    ptt = pta
    pta -= 1

    if arr[pta] > arr[ptt]:
        key = arr[ptt]
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1

        if pta > start and arr[pta - 1] > key:
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1

        if pta >= start and arr[pta] > key:
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1

        arr[ptt] = key
    return end


def tail_swap_eight(arr, start, end):
    # Same shift logic as swap_five, one neighbor further out (checks pta - 2 first). Returns
    # the new `end`.
    pta = end
    end += 1
    ptt = pta
    pta -= 1

    if arr[pta] > arr[ptt]:
        key = arr[ptt]
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1

        if arr[pta - 2] > key:
            for _ in range(3):
                arr[ptt] = arr[pta]
                ptt -= 1
                pta -= 1

        if pta > start and arr[pta - 1] > key:
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1

        if pta >= start and arr[pta] > key:
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1

        arr[ptt] = key
    return end


def swap_six(arr, start, end):
    end = swap_five(arr, start, end)
    return tail_swap_eight(arr, start, end)


def swap_seven(arr, start, end):
    end = swap_six(arr, start, end)
    return tail_swap_eight(arr, start, end)


def swap_eight(arr, start, end):
    end = swap_seven(arr, start, end)
    return tail_swap_eight(arr, start, end)


def tail_swap(arr, start, nmemb):
    # ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
    # swap_five through swap_eight handle the first 5-8 elements by hand, then a binary-search
    # insertion (the `while top > 1` loop) places everything past index 8.
    end = 0
    if nmemb in (0, 1):
        return
    if nmemb == 2:
        swap_two(arr, start)
        return
    if nmemb == 3:
        swap_three(arr, start)
        return
    if nmemb == 4:
        swap_four(arr, start)
        return
    if nmemb == 5:
        swap_four(arr, start)
        swap_five(arr, start, end)
        return
    if nmemb == 6:
        swap_four(arr, start)
        swap_six(arr, start, end)
        return
    if nmemb == 7:
        swap_four(arr, start)
        swap_seven(arr, start, end)
        return
    if nmemb == 8:
        swap_four(arr, start)
        swap_eight(arr, start, end)
        return

    swap_four(arr, start)
    swap_eight(arr, start, end)
    end = start + 8
    offset = 8

    while offset < nmemb:
        top = offset
        offset += 1
        pta = end
        end += 1
        ptt = pta
        pta -= 1

        if arr[pta] <= arr[ptt]:
            continue

        temp = arr[ptt]
        while top > 1:
            mid = top // 2
            if arr[pta - mid] > temp:
                pta -= mid
            top -= mid

        i = ptt
        while i > pta:
            arr[i] = arr[i - 1]
            i -= 1
        arr[pta] = temp


# -- Parity merges (merge 4+4 into 8, or 8+8 into 16, tracking both ends at once) ---------------


def parity_merge4(arr, start, dest, aux_offset):
    # Merges the two 4-element runs at [start, start+4) and [start+4, start+8) from the main
    # array into dest (a scratch buffer), working from both ends toward the middle
    # simultaneously -- forward comparisons use <= and backward ones use >, which is what keeps
    # this stable.
    aux_p = aux_offset
    ptl = start
    ptr = start + 4

    for _ in range(3):
        if arr[ptl] <= arr[ptr]:
            dest[aux_p] = arr[ptl]
            ptl += 1
        else:
            dest[aux_p] = arr[ptr]
            ptr += 1
        aux_p += 1
    dest[aux_p] = min(arr[ptl], arr[ptr])

    ptl = start + 3
    ptr = start + 7
    aux_p += 4

    for _ in range(3):
        if arr[ptl] > arr[ptr]:
            dest[aux_p] = arr[ptl]
            ptl -= 1
        else:
            dest[aux_p] = arr[ptr]
            ptr -= 1
        aux_p -= 1
    dest[aux_p] = max(arr[ptr], arr[ptl])


def parity_merge8(arr, from_, start):
    # Same shape as parity_merge4, one level up: merges two 8-element runs from `from_` (a
    # scratch buffer) back into the main array.
    main_p = start
    ptl = 0
    ptr = 8

    for _ in range(7):
        if from_[ptl] <= from_[ptr]:
            arr[main_p] = from_[ptl]
            ptl += 1
        else:
            arr[main_p] = from_[ptr]
            ptr += 1
        main_p += 1
    arr[main_p] = min(from_[ptl], from_[ptr])

    ptl = 7
    ptr = 15
    main_p += 8

    for _ in range(7):
        if from_[ptl] > from_[ptr]:
            arr[main_p] = from_[ptl]
            ptl -= 1
        else:
            arr[main_p] = from_[ptr]
            ptr -= 1
        main_p -= 1
    arr[main_p] = max(from_[ptr], from_[ptl])


def parity_merge16(arr, start, aux):
    # Merges four already-sorted 4-element runs (16 elements total) via two parity_merge4 passes
    # into aux, then one parity_merge8 pass back -- but only if they aren't already sorted,
    # which the three comparisons below check cheaply.
    if (
        arr[start + 3] <= arr[start + 4]
        and arr[start + 7] <= arr[start + 8]
        and arr[start + 11] <= arr[start + 12]
    ):
        return

    parity_merge4(arr, start, aux, 0)
    parity_merge4(arr, start + 8, aux, 8)
    parity_merge8(arr, aux, start)


# -- Bottom-up tail merge (arrays under 256, and quad_merge's own fallback tail) -----------------


def partial_backward_merge(arr, aux, start, nmemb, block):
    m = start + block
    e = start + nmemb - 1
    r = m
    m -= 1

    if arr[m] <= arr[r]:
        return
    while arr[m] <= arr[e]:
        e -= 1

    for i in range(r, r + (e - m)):
        aux[i - r] = arr[i]

    s = e - r
    arr[e] = arr[m]
    e -= 1
    m -= 1

    if arr[start] <= aux[0]:
        while True:
            while arr[m] > aux[s]:
                arr[e] = arr[m]
                e -= 1
                m -= 1
            arr[e] = aux[s]
            e -= 1
            s -= 1
            if s < 0:
                break
    else:
        while True:
            while arr[m] <= aux[s]:
                arr[e] = aux[s]
                e -= 1
                s -= 1
            arr[e] = arr[m]
            e -= 1
            m -= 1
            if m < start:
                break
        while True:
            arr[e] = aux[s]
            e -= 1
            s -= 1
            if s < 0:
                break


def tail_merge(arr, aux, start, nmemb, block):
    # Bottom-up merge pass: doubles `block` each round, merging every adjacent pair of runs at
    # the current width via partial_backward_merge, until `block` covers the whole
    # [start, start + nmemb) range. Used directly for arrays under 256, and as quad_merge's
    # fallback tail for whatever doesn't divide evenly into quad blocks.
    pte = start + nmemb

    while block < nmemb:
        pta = start
        while pta + block < pte:
            if pta + block * 2 < pte:
                partial_backward_merge(arr, aux, pta, block * 2, block)
                pta += block * 2
                continue
            partial_backward_merge(arr, aux, pta, pte - pta, block)
            break
        block *= 2


# -- Quad merge (arrays 256 and up) -------------------------------------------------------------


def forward_merge_read(arr, aux, to_aux, i):
    return arr[i] if to_aux else aux[i]


def forward_merge_write(arr, aux, to_aux, i, value):
    if to_aux:
        aux[i] = value
    else:
        arr[i] = value


def forward_merge(arr, aux, start, aux_start, block, to_aux):
    # Merges main-array run [start, start+block) with aux-buffer run starting at aux_start (or
    # vice versa, controlled by to_aux) into the other side.
    merge_p = aux_start if to_aux else start
    lo = start if to_aux else aux_start
    r = (start + block) if to_aux else (aux_start + block)
    m = r
    e = r + block

    if forward_merge_read(arr, aux, to_aux, r - 1) <= forward_merge_read(
        arr, aux, to_aux, e - 1
    ):
        while lo < m:
            if forward_merge_read(arr, aux, to_aux, lo) <= forward_merge_read(
                arr, aux, to_aux, r
            ):
                forward_merge_write(
                    arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, lo)
                )
                merge_p += 1
                lo += 1
            else:
                forward_merge_write(
                    arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r)
                )
                merge_p += 1
                r += 1
        while r < e:
            forward_merge_write(
                arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r)
            )
            merge_p += 1
            r += 1
    else:
        while r < e:
            if forward_merge_read(arr, aux, to_aux, lo) > forward_merge_read(
                arr, aux, to_aux, r
            ):
                forward_merge_write(
                    arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r)
                )
                merge_p += 1
                r += 1
            else:
                forward_merge_write(
                    arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, lo)
                )
                merge_p += 1
                lo += 1
        while lo < m:
            forward_merge_write(
                arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, lo)
            )
            merge_p += 1
            lo += 1


def quad_merge_block(arr, start, aux, block):
    # Merges 4 adjacent `block`-sized runs ([start, start+4*block)) into one sorted run, via up
    # to 3 already-sorted fast-path checks that skip straight to a smaller merge -- or none at
    # all -- when consecutive runs are already in order.
    block_x2 = block * 2
    c_max = start + block

    if arr[c_max - 1] <= arr[c_max]:
        c_max += block_x2

        if arr[c_max - 1] <= arr[c_max]:
            c_max -= block

            if arr[c_max - 1] <= arr[c_max]:
                return

            pts = 0
            c = start
            while True:
                aux[pts] = arr[c]
                c += 1
                pts += 1
                if c >= c_max:
                    break

            c_max = c + block_x2
            while True:
                aux[pts] = arr[c]
                c += 1
                pts += 1
                if c >= c_max:
                    break

            forward_merge(arr, aux, start, 0, block_x2, False)
            return

        pts = 0
        c = start
        c_max = start + block_x2
        while True:
            aux[pts] = arr[c]
            c += 1
            pts += 1
            if c >= c_max:
                break
    else:
        forward_merge(arr, aux, start, 0, block, True)

    forward_merge(arr, aux, start + block_x2, block_x2, block, True)
    forward_merge(arr, aux, start, 0, block_x2, False)


def quad_merge(arr, aux, start, nmemb, block):
    # Quad-merges the entire [start, start+nmemb) range, doubling `block` by 4 each round; falls
    # back to tail_merge for whatever doesn't divide evenly into quad blocks at the current size,
    # and again at the very end for the final, coarsest remainder.
    pte = start + nmemb
    block = block * 4

    while block * 2 <= nmemb:
        pta = start
        while True:
            quad_merge_block(arr, pta, aux, block // 4)
            pta += block
            if pta + block > pte:
                break
        tail_merge(arr, aux, pta, pte - pta, block // 4)
        block *= 4
    tail_merge(arr, aux, start, nmemb, block // 4)


# -- Pre-sort pass -------------------------------------------------------------------------------


def quad_swap(arr, start, nmemb):
    # Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
    # detector for strictly-decreasing runs -- reversed in place rather than merged, since a
    # reversal is cheaper and exactly reproduces a decreasing run's sorted order. If the *entire*
    # range turns out strictly decreasing, one reversal finishes the sort outright (returns
    # True); otherwise this finishes with parity-merge passes over what's left (returns False,
    # meaning the caller still has more merging to do).
    #
    # The original C source expresses this with `goto` between the outer "swapper" loop and an
    # inner "innerB" loop. Python has neither goto nor labeled loops, so the two loops are
    # flattened into one `while True` driven by an `in_inner_b` mode flag: `continue` while the
    # flag is unchanged plays the role of a same-loop `continue`/`goto swapper_continue` handled
    # without switching modes, flipping `in_inner_b` before `continue` plays the role of
    # `goto innerB` / falling back out of it, and `break` plays `goto swapper_end`.
    swap_buf = [0] * 16
    pta = start
    count = nmemb // 4
    pts = 0
    in_inner_b = False

    while True:
        if not in_inner_b:
            if count <= 0:
                break
            count -= 1

            if arr[pta] > arr[pta + 1]:
                if arr[pta + 2] > arr[pta + 3]:
                    if arr[pta + 1] > arr[pta + 2]:
                        pts = pta
                        pta += 4
                        in_inner_b = True
                        continue
                    swap2(arr, pta + 2, pta + 3)
                swap2(arr, pta, pta + 1)
            elif arr[pta + 2] > arr[pta + 3]:
                swap2(arr, pta + 2, pta + 3)

            if arr[pta + 1] > arr[pta + 2]:
                if arr[pta] <= arr[pta + 2]:
                    if arr[pta + 1] <= arr[pta + 3]:
                        swap2(arr, pta + 1, pta + 2)
                    else:
                        temp = arr[pta + 1]
                        arr[pta + 1] = arr[pta + 2]
                        arr[pta + 2] = arr[pta + 3]
                        arr[pta + 3] = temp
                elif arr[pta] > arr[pta + 3]:
                    swap2(arr, pta + 1, pta + 3)
                    swap2(arr, pta, pta + 2)
                elif arr[pta + 1] <= arr[pta + 3]:
                    temp = arr[pta + 1]
                    arr[pta + 1] = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = temp
                else:
                    temp = arr[pta + 1]
                    arr[pta + 1] = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = arr[pta + 3]
                    arr[pta + 3] = temp
            pta += 4
            continue

        # innerB
        if count > 0:
            count -= 1

            if arr[pta] > arr[pta + 1]:
                if arr[pta + 2] > arr[pta + 3]:
                    if arr[pta + 1] > arr[pta + 2] and arr[pta - 1] > arr[pta]:
                        pta += 4
                        continue
                    swap2(arr, pta + 2, pta + 3)
                swap2(arr, pta, pta + 1)
            elif arr[pta + 2] > arr[pta + 3]:
                swap2(arr, pta + 2, pta + 3)

            if arr[pta + 1] > arr[pta + 2]:
                if arr[pta] <= arr[pta + 2]:
                    if arr[pta + 1] <= arr[pta + 3]:
                        swap2(arr, pta + 1, pta + 2)
                    else:
                        temp = arr[pta + 1]
                        arr[pta + 1] = arr[pta + 2]
                        arr[pta + 2] = arr[pta + 3]
                        arr[pta + 3] = temp
                elif arr[pta] > arr[pta + 3]:
                    swap2(arr, pta, pta + 2)
                    swap2(arr, pta + 1, pta + 3)
                elif arr[pta + 1] <= arr[pta + 3]:
                    temp = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = arr[pta + 1]
                    arr[pta + 1] = temp
                else:
                    temp = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = arr[pta + 3]
                    arr[pta + 3] = arr[pta + 1]
                    arr[pta + 1] = temp

            reverse_inclusive(arr, pts, pta - 1)
            pta += 4
            in_inner_b = False
            continue

        if pts == start:
            remainder = nmemb % 4
            if remainder == 3:
                remainder = 2 if arr[pta + 1] > arr[pta + 2] else -1
            if remainder == 2:
                remainder = 1 if arr[pta] > arr[pta + 1] else -1
            if remainder == 1:
                remainder = 0 if arr[pta - 1] > arr[pta] else -1
            if remainder == 0:
                reverse_inclusive(arr, pts, pts + nmemb - 1)
                return True

        reverse_inclusive(arr, pts, pta - 1)
        break

    tail_swap(arr, pta, nmemb % 4)

    pta = start
    count = nmemb // 16
    while count > 0:
        count -= 1
        parity_merge16(arr, pta, swap_buf)
        pta += 16

    if nmemb % 16 > 4:
        tail_merge(arr, swap_buf, pta, nmemb % 16, 4)

    return False


# -- Entry point -----------------------------------------------------------------------------


def sort(arr):
    # Top-level dispatch by size: under 16 is a plain tail_swap; under 256 pre-sorts via
    # quad_swap then finishes with tail_merge; 256 and up finishes with the full quad_merge pass
    # instead.
    n = len(arr)
    if n < 16:
        tail_swap(arr, 0, n)
    elif n < 256:
        if not quad_swap(arr, 0, n):
            buffer = [0] * 128
            tail_merge(arr, buffer, 0, n, 16)
    else:
        if not quad_swap(arr, 0, n):
            buffer = [0] * (n // 2)
            quad_merge(arr, buffer, 0, n, 16)


if __name__ == "__main__":
    array = [
        55,
        12,
        84,
        3,
        47,
        91,
        26,
        68,
        8,
        73,
        40,
        97,
        15,
        62,
        34,
        79,
        21,
        88,
        5,
        51,
        66,
        29,
        44,
        12,
        90,
        1,
        58,
        33,
        71,
        19,
        60,
        45,
        27,
        82,
        6,
        95,
        38,
        63,
        9,
        50,
    ]
    sort(array)
    print(array)
