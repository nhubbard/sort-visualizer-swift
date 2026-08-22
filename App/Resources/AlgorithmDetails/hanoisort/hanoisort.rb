def sort(arr)
  n = arr.length
  return if n <= 1

  stack2 = []
  stack3 = []

  push = lambda do |id, value|
    if id == :two
      stack2.push(value)
    else
      stack3.push(value)
    end
  end

  pop = lambda do |id|
    (id == :two) ? stack2.pop : stack3.pop
  end

  peek = lambda do |id|
    (id == :two) ? stack2.last : stack3.last
  end

  empty = lambda do |id|
    (id == :two) ? stack2.empty? : stack3.empty?
  end

  sp = 0
  unsorted = 0
  target = 0
  target_moves = 0

  move_from_main = lambda do |id, check_unsorted|
    duplicates = 1
    push.call(id, arr[sp])
    sp += 1
    end_on_length = sp >= n || (check_unsorted && sp >= unsorted)
    while !end_on_length && arr[sp] == peek.call(id)
      duplicates += 1
      push.call(id, arr[sp])
      sp += 1
      end_on_length = sp >= n || (check_unsorted && sp >= unsorted)
    end
    duplicates
  end

  move_to_main = lambda do |id|
    sp -= 1
    arr[sp] = pop.call(id)
    while !empty.call(id) && peek.call(id) == arr[sp]
      sp -= 1
      arr[sp] = pop.call(id)
    end
  end

  move_between_stacks = lambda do |from_id, to_id|
    push.call(to_id, pop.call(from_id))
    while !empty.call(from_id) && peek.call(from_id) == peek.call(to_id)
      push.call(to_id, pop.call(from_id))
    end
  end

  valid_number_moves = lambda do |moves|
    if moves.zero?
      true
    elsif moves.even?
      false
    else
      valid_number_moves.call(moves / 2)
    end
  end

  get_height = lambda do |moves_plus_1|
    if moves_plus_1 == 1
      0
    else
      get_height.call(moves_plus_1 / 2) + 1
    end
  end

  end_con_met = lambda do |end_con, moves|
    if !valid_number_moves.call(moves)
      false
    else
      case end_con
      when 1
        stack2.empty? || target <= stack2.last
      when 2
        moves == target_moves
      when 3
        stack2.empty?
      else
        raise "unknown end condition"
      end
    end
  end

  hanoi = lambda do |start_stack, go_right, end_con|
    moves = 0
    min_pole_loc = start_stack

    unless end_con_met.call(end_con, moves)
      moves += 1
      case min_pole_loc
      when 1
        if go_right
          move_from_main.call(:two, true)
          min_pole_loc = 2
        else
          move_from_main.call(:three, true)
          min_pole_loc = 3
        end
      when 2
        if go_right
          move_between_stacks.call(:two, :three)
          min_pole_loc = 3
        else
          move_to_main.call(:two)
          min_pole_loc = 1
        end
      else
        if go_right
          move_to_main.call(:three)
          min_pole_loc = 1
        else
          move_between_stacks.call(:three, :two)
          min_pole_loc = 2
        end
      end
    end

    until end_con_met.call(end_con, moves)
      moves += 2
      case min_pole_loc
      when 1
        if !stack2.empty? && (stack3.empty? || stack2.last < stack3.last)
          move_between_stacks.call(:two, :three)
        else
          move_between_stacks.call(:three, :two)
        end
        if go_right
          move_from_main.call(:two, true)
          min_pole_loc = 2
        else
          move_from_main.call(:three, true)
          min_pole_loc = 3
        end
      when 2
        if stack3.empty? || (sp < unsorted && arr[sp] < stack3.last)
          move_from_main.call(:three, true)
        else
          move_to_main.call(:three)
        end
        if go_right
          move_between_stacks.call(:two, :three)
          min_pole_loc = 3
        else
          move_to_main.call(:two)
          min_pole_loc = 1
        end
      else
        if stack2.empty? || (sp < unsorted && arr[sp] < stack2.last)
          move_from_main.call(:two, true)
        else
          move_to_main.call(:two)
        end
        if go_right
          move_to_main.call(:three)
          min_pole_loc = 1
        else
          move_between_stacks.call(:three, :two)
          min_pole_loc = 2
        end
      end
    end

    moves
  end

  remove_from_main_stack = lambda do
    target = arr[sp]
    moves = hanoi.call(2, true, 1)
    height = get_height.call(moves + 1)
    target_moves = moves
    even_height = height.even?

    hanoi.call(1, true, 2) if even_height
    unsorted += move_from_main.call(:two, false)
    hanoi.call(3, even_height, 2)
  end

  return_to_main_stack = lambda do
    moves = hanoi.call(2, true, 3)
    height = get_height.call(moves + 1)
    if height.odd?
      target_moves = moves
      hanoi.call(3, true, 2)
    end
  end

  remove_from_main_stack.call while unsorted < n
  return_to_main_stack.call
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
