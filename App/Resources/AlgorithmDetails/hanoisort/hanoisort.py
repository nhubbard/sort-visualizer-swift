def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    STACK_TWO = "two"
    STACK_THREE = "three"

    stack2 = []
    stack3 = []

    def push(stack_id, value):
        if stack_id == STACK_TWO:
            stack2.append(value)
        else:
            stack3.append(value)

    def pop(stack_id):
        if stack_id == STACK_TWO:
            return stack2.pop()
        else:
            return stack3.pop()

    def peek(stack_id):
        stack = stack2 if stack_id == STACK_TWO else stack3
        return stack[-1] if stack else None

    def is_empty(stack_id):
        stack = stack2 if stack_id == STACK_TWO else stack3
        return len(stack) == 0

    sp = 0
    unsorted = 0
    target = 0
    target_moves = 0

    def move_from_main(stack_id, check_unsorted):
        nonlocal sp
        duplicates = 1
        push(stack_id, arr[sp])
        sp += 1
        end_on_length = sp >= n or (check_unsorted and sp >= unsorted)
        while not end_on_length and arr[sp] == peek(stack_id):
            duplicates += 1
            push(stack_id, arr[sp])
            sp += 1
            end_on_length = sp >= n or (check_unsorted and sp >= unsorted)
        return duplicates

    def move_to_main(stack_id):
        nonlocal sp
        sp -= 1
        arr[sp] = pop(stack_id)
        while not is_empty(stack_id) and peek(stack_id) == arr[sp]:
            sp -= 1
            arr[sp] = pop(stack_id)

    def move_between_stacks(from_id, to_id):
        push(to_id, pop(from_id))
        while not is_empty(from_id) and peek(from_id) == peek(to_id):
            push(to_id, pop(from_id))

    def valid_number_moves(moves):
        if moves == 0:
            return True
        if moves % 2 == 0:
            return False
        return valid_number_moves(moves // 2)

    def get_height(moves_plus_1):
        if moves_plus_1 == 1:
            return 0
        return get_height(moves_plus_1 // 2) + 1

    def end_con_met(end_con, moves):
        if not valid_number_moves(moves):
            return False
        if end_con == 1:
            return len(stack2) == 0 or target <= stack2[-1]
        if end_con == 2:
            return moves == target_moves
        if end_con == 3:
            return len(stack2) == 0
        raise ValueError("unknown end condition")

    def hanoi(start_stack, go_right, end_con):
        nonlocal target_moves
        moves = 0
        min_pole_loc = start_stack

        if not end_con_met(end_con, moves):
            moves += 1
            if min_pole_loc == 1:
                if go_right:
                    move_from_main(STACK_TWO, True)
                    min_pole_loc = 2
                else:
                    move_from_main(STACK_THREE, True)
                    min_pole_loc = 3
            elif min_pole_loc == 2:
                if go_right:
                    move_between_stacks(STACK_TWO, STACK_THREE)
                    min_pole_loc = 3
                else:
                    move_to_main(STACK_TWO)
                    min_pole_loc = 1
            else:
                if go_right:
                    move_to_main(STACK_THREE)
                    min_pole_loc = 1
                else:
                    move_between_stacks(STACK_THREE, STACK_TWO)
                    min_pole_loc = 2

        while not end_con_met(end_con, moves):
            moves += 2
            if min_pole_loc == 1:
                if stack2 and (not stack3 or stack2[-1] < stack3[-1]):
                    move_between_stacks(STACK_TWO, STACK_THREE)
                else:
                    move_between_stacks(STACK_THREE, STACK_TWO)
                if go_right:
                    move_from_main(STACK_TWO, True)
                    min_pole_loc = 2
                else:
                    move_from_main(STACK_THREE, True)
                    min_pole_loc = 3
            elif min_pole_loc == 2:
                if not stack3 or (sp < unsorted and arr[sp] < stack3[-1]):
                    move_from_main(STACK_THREE, True)
                else:
                    move_to_main(STACK_THREE)
                if go_right:
                    move_between_stacks(STACK_TWO, STACK_THREE)
                    min_pole_loc = 3
                else:
                    move_to_main(STACK_TWO)
                    min_pole_loc = 1
            else:
                if not stack2 or (sp < unsorted and arr[sp] < stack2[-1]):
                    move_from_main(STACK_TWO, True)
                else:
                    move_to_main(STACK_TWO)
                if go_right:
                    move_to_main(STACK_THREE)
                    min_pole_loc = 1
                else:
                    move_between_stacks(STACK_THREE, STACK_TWO)
                    min_pole_loc = 2

        return moves

    def remove_from_main_stack():
        nonlocal target, target_moves, unsorted
        target = arr[sp]
        moves = hanoi(2, True, 1)
        height = get_height(moves + 1)
        target_moves = moves
        even_height = height % 2 == 0

        if even_height:
            hanoi(1, True, 2)
        unsorted += move_from_main(STACK_TWO, False)
        hanoi(3, even_height, 2)

    def return_to_main_stack():
        nonlocal target_moves
        moves = hanoi(2, True, 3)
        height = get_height(moves + 1)
        if height % 2 == 1:
            target_moves = moves
            hanoi(3, True, 2)

    while unsorted < n:
        remove_from_main_stack()
    return_to_main_stack()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
