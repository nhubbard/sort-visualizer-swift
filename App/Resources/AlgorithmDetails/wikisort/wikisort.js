// The WikiSorting source is released to the public domain under the Unlicense.

class WikiRange {
  constructor(start=0, end=0) {
    this.start = start;
    this.end = end;
  }
  get length() {
    return (this.end - this.start);
  }
  set(start, end) {
    [this.start, this.end] = [start, end];
  }
  copy() {
    return new WikiRange(this.start, this.end);
  }
}
class WikiPull {
  constructor(from_=0, to=0, count=0, range=null) {
    this.from_ = from_;
    this.to = to;
    this.count = count;
    this.range = ((range === null) ? new WikiRange() : range);
  }
}
class WikiIterator {
  constructor(size) {
    this.size = size;
    this.denominator = Math.floor((1 << ((Math.floor(Math.log2(size)) + 1) - 1)) / 4);
    this.numeratorStep = (size % this.denominator);
    this.decimalStep = Math.floor(size / this.denominator);
    this.numerator = 0;
    this.decimal = 0;
  }
  begin() {
    this.numerator = 0;
    this.decimal = 0;
  }
  nextRange() {
    let start;
    start = this.decimal;
    this.decimal += this.decimalStep;
    this.numerator += this.numeratorStep;
    if ((this.numerator >= this.denominator)) {
      this.numerator -= this.denominator;
      this.decimal += 1;
    }
    return new WikiRange(start, this.decimal);
  }
  get finished() {
    return (this.decimal >= this.size);
  }
  nextLevel() {
    this.decimalStep += this.decimalStep;
    this.numeratorStep += this.numeratorStep;
    if ((this.numeratorStep >= this.denominator)) {
      this.numeratorStep -= this.denominator;
      this.decimalStep += 1;
    }
    return (this.decimalStep < this.size);
  }
  get length() {
    return this.decimalStep;
  }
}
class WikiSortExample {
  constructor(input) {
    this.values = input;
  }
  read(index) {
    return this.values[index];
  }
  less(left, right) {
    return (this.values[left] < this.values[right]);
  }
  lessValues(left, right) {
    return (left < right);
  }
  greaterValues(left, right) {
    return (left > right);
  }
  swap(left, right) {
    [this.values[left], this.values[right]] = [this.values[right], this.values[left]];
  }
  binaryFirst(value, range) {
    let end, middle, start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + Math.floor((end - start) / 2));
      if ((this.values[middle] < value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  binaryLast(value, range) {
    let end, middle, start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + Math.floor((end - start) / 2));
      if ((this.values[middle] <= value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  findFirstForward(value, range, unique) {
    let index, skip;
    if (!((range.length > 0))) {
      return range.start;
    }
    skip = Math.max(Math.floor(range.length / Math.max(unique, 1)), 1);
    index = (range.start + skip);
    while ((this.values[(index - 1)] < value)) {
      if ((index >= (range.end - skip))) {
        return this.binaryFirst(value, new WikiRange(index, range.end));
      }
      index += skip;
    }
    return this.binaryFirst(value, new WikiRange((index - skip), index));
  }
  findLastForward(value, range, unique) {
    let index, skip;
    if (!((range.length > 0))) {
      return range.start;
    }
    skip = Math.max(Math.floor(range.length / Math.max(unique, 1)), 1);
    index = (range.start + skip);
    while ((this.values[(index - 1)] <= value)) {
      if ((index >= (range.end - skip))) {
        return this.binaryLast(value, new WikiRange(index, range.end));
      }
      index += skip;
    }
    return this.binaryLast(value, new WikiRange((index - skip), index));
  }
  findFirstBackward(value, range, unique) {
    let index, skip;
    if (!((range.length > 0))) {
      return range.start;
    }
    skip = Math.max(Math.floor(range.length / Math.max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (this.values[(index - 1)] >= value))) {
      if ((index < (range.start + skip))) {
        return this.binaryFirst(value, new WikiRange(range.start, index));
      }
      index -= skip;
    }
    return this.binaryFirst(value, new WikiRange(index, (index + skip)));
  }
  findLastBackward(value, range, unique) {
    let index, skip;
    if (!((range.length > 0))) {
      return range.start;
    }
    skip = Math.max(Math.floor(range.length / Math.max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (this.values[(index - 1)] > value))) {
      if ((index < (range.start + skip))) {
        return this.binaryLast(value, new WikiRange(range.start, index));
      }
      index -= skip;
    }
    return this.binaryLast(value, new WikiRange(index, (index + skip)));
  }
  insertionSort(range) {
    let cursor, destination, index, value;
    if (!((range.length > 1))) {
      return;
    }
    for (index = (range.start + 1); index < range.end; index++) {
      value = this.read(index);
      destination = this.binaryLast(value, new WikiRange(range.start, index));
      cursor = index;
      while ((cursor > destination)) {
        this.values[cursor] = this.read((cursor - 1));
        cursor -= 1;
      }
      this.values[destination] = value;
    }
  }
  blockSwap(first, second, length) {
    let offset;
    if (!((length > 0))) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      this.swap((first + offset), (second + offset));
    }
  }
  rotate(amount, range) {
    let leftLength, position, rightLength, split;
    if (!((range.length > 0))) {
      return;
    }
    split = ((amount >= 0) ? (range.start + amount) : (range.end + amount));
    if (!(((range.start < split) && (split < range.end)))) {
      return;
    }
    position = range.start;
    leftLength = (split - range.start);
    rightLength = (range.end - split);
    while (((leftLength !== 0) && (rightLength !== 0))) {
      if ((leftLength <= rightLength)) {
        this.blockSwap(position, (position + leftLength), leftLength);
        position += leftLength;
        rightLength -= leftLength;
      } else {
        this.blockSwap(((position + leftLength) - rightLength), (position + leftLength), rightLength);
        leftLength -= rightLength;
      }
    }
  }
  mergeInternal(left, right, buffer) {
    let aCount, bCount, insert;
    aCount = 0;
    bCount = 0;
    insert = 0;
    if (((right.length > 0) && (left.length > 0))) {
      while (true) {
        if (!(this.less((right.start + bCount), (buffer.start + aCount)))) {
          this.swap((left.start + insert), (buffer.start + aCount));
          aCount += 1;
          insert += 1;
          if ((aCount >= left.length)) {
            break;
          }
        } else {
          this.swap((left.start + insert), (right.start + bCount));
          bCount += 1;
          insert += 1;
          if ((bCount >= right.length)) {
            break;
          }
        }
      }
    }
    this.blockSwap((buffer.start + aCount), (left.start + insert), (left.length - aCount));
  }
  mergeInPlace(originalLeft, originalRight) {
    let amount, left, middle, right;
    if (!(((originalLeft.length > 0) && (originalRight.length > 0)))) {
      return;
    }
    left = originalLeft;
    right = originalRight;
    while (true) {
      middle = this.binaryFirst(this.read(left.start), right);
      amount = (middle - left.end);
      this.rotate(-(amount), new WikiRange(left.start, middle));
      if ((right.end === middle)) {
        break;
      }
      right.start = middle;
      left.set((left.start + amount), right.start);
      left.start = this.binaryLast(this.read(left.start), left);
      if ((left.length === 0)) {
        break;
      }
    }
  }
  netSwap(range, order, x, y) {
    let a, b, first, isEqual, isGreater, second;
    first = (range.start + x);
    second = (range.start + y);
    a = this.read(first);
    b = this.read(second);
    isGreater = this.greaterValues(a, b);
    isEqual = (!(isGreater) && !(this.lessValues(a, b)));
    if ((isGreater || (isEqual && (order[x] > order[y])))) {
      this.swap(first, second);
      [order[x], order[y]] = [order[y], order[x]];
    }
  }
  sortSmallRuns(iterator) {
    let order, pairs, range, x, y;
    while (!(iterator.finished)) {
      order = Array.from({length: 8}, (_, i) => i);
      range = iterator.nextRange();
      pairs = [];
      if ((range.length === 8)) {
        pairs = [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [1, 2], [5, 6], [0, 4], [3, 7], [1, 5], [2, 6], [1, 4], [3, 6], [2, 4], [3, 5], [3, 4]];
      } else {
        if ((range.length === 7)) {
          pairs = [[1, 2], [3, 4], [5, 6], [0, 2], [3, 5], [4, 6], [0, 1], [4, 5], [2, 6], [0, 4], [1, 5], [0, 3], [2, 5], [1, 3], [2, 4], [2, 3]];
        } else {
          if ((range.length === 6)) {
            pairs = [[1, 2], [4, 5], [0, 2], [3, 5], [0, 1], [3, 4], [2, 5], [0, 3], [1, 4], [2, 4], [1, 3], [2, 3]];
          } else {
            if ((range.length === 5)) {
              pairs = [[0, 1], [3, 4], [2, 4], [2, 3], [1, 4], [0, 3], [0, 2], [1, 3], [1, 2]];
            } else {
              if ((range.length === 4)) {
                pairs = [[0, 1], [2, 3], [0, 2], [1, 3], [1, 2]];
              } else {
                pairs = [];
              }
            }
          }
        }
      }
      for (const [x, y] of pairs) {
        this.netSwap(range, order, x, y);
      }
    }
  }
  sort() {
    let amount, blockA, blockB, blockSize, buffer, buffer1, buffer2, bufferSize, count, find, findA, findSeparately, firstA, index, indexA, iterator, last, lastA, lastB, left, length, minimum, nominalBlock, pull, pullIndex, pulls, range, remaining, right, size, split, start, targetBufferSize, unique;
    size = this.values.length;
    if ((size < 4)) {
      this.insertionSort(new WikiRange(0, size));
      return;
    }
    iterator = new WikiIterator(size);
    this.sortSmallRuns(iterator);
    if ((size < 8)) {
      return;
    }
    while (true) {
      nominalBlock = Math.max(1, Math.floor(Math.sqrt(iterator.length)));
      blockSize = nominalBlock;
      targetBufferSize = (Math.floor(iterator.length / blockSize) + 1);
      buffer1 = new WikiRange();
      buffer2 = new WikiRange();
      pulls = [new WikiPull(), new WikiPull()];
      pullIndex = 0;
      find = (targetBufferSize * 2);
      findSeparately = false;
      if ((find > iterator.length)) {
        find = targetBufferSize;
        findSeparately = true;
      }
      iterator.begin();
      while (!(iterator.finished)) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        last = left.start;
        count = 1;
        index = last;
        while ((count < find)) {
          index = this.findLastForward(this.read(last), new WikiRange((last + 1), left.end), (find - count));
          if ((index === left.end)) {
            break;
          }
          last = index;
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = new WikiPull(index, left.start, count, new WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count === (targetBufferSize * 2))) {
            buffer1 = new WikiRange(left.start, (left.start + targetBufferSize));
            buffer2 = new WikiRange((left.start + targetBufferSize), (left.start + count));
            break;
          } else {
            if ((find === (targetBufferSize * 2))) {
              buffer1 = new WikiRange(left.start, (left.start + count));
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = new WikiRange(left.start, (left.start + count));
                findSeparately = false;
              } else {
                buffer2 = new WikiRange(left.start, (left.start + count));
                break;
              }
            }
          }
        } else {
          if (((pullIndex === 0) && (count > buffer1.length))) {
            buffer1 = new WikiRange(left.start, (left.start + count));
            pulls[pullIndex] = new WikiPull(index, left.start, count, new WikiRange(left.start, right.end));
          }
        }
        last = (right.end - 1);
        count = 1;
        while ((count < find)) {
          index = this.findFirstBackward(this.read(last), new WikiRange(right.start, last), (find - count));
          if ((index === right.start)) {
            break;
          }
          last = (index - 1);
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = new WikiPull(index, right.end, count, new WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count === (targetBufferSize * 2))) {
            buffer1 = new WikiRange((right.end - count), (right.end - targetBufferSize));
            buffer2 = new WikiRange((right.end - targetBufferSize), right.end);
            break;
          } else {
            if ((find === (targetBufferSize * 2))) {
              buffer1 = new WikiRange((right.end - count), right.end);
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = new WikiRange((right.end - count), right.end);
                findSeparately = false;
              } else {
                if ((pulls[0].range.start === left.start)) {
                  pulls[0].range.end -= pulls[1].count;
                }
                buffer2 = new WikiRange((right.end - count), right.end);
                break;
              }
            }
          }
        } else {
          if (((pullIndex === 0) && (count > buffer1.length))) {
            buffer1 = new WikiRange((right.end - count), right.end);
            pulls[pullIndex] = new WikiPull(index, right.end, count, new WikiRange(left.start, right.end));
          }
        }
      }
      for (pull = 0; pull < 2; pull++) {
        length = pulls[pull].count;
        if ((pulls[pull].to < pulls[pull].from_)) {
          index = pulls[pull].from_;
          if ((length > 1)) {
            for (count = 1; count < length; count++) {
              index = this.findFirstBackward(this.read((index - 1)), new WikiRange(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count));
              range = new WikiRange((index + 1), (pulls[pull].from_ + 1));
              this.rotate((range.length - count), range);
              pulls[pull].from_ = (index + count);
            }
          }
        } else {
          if ((pulls[pull].to > pulls[pull].from_)) {
            index = (pulls[pull].from_ + 1);
            if ((length > 1)) {
              for (count = 1; count < length; count++) {
                index = this.findLastForward(this.read(index), new WikiRange(index, pulls[pull].to), (length - count));
                range = new WikiRange(pulls[pull].from_, (index - 1));
                this.rotate(count, range);
                pulls[pull].from_ = ((index - 1) - count);
              }
            }
          }
        }
      }
      bufferSize = buffer1.length;
      blockSize = (Math.floor(iterator.length / bufferSize) + 1);
      iterator.begin();
      while (!(iterator.finished)) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        start = left.start;
        for (const pull of pulls) {
          if ((start !== pull.range.start)) {
            continue;
          }
          if ((pull.from_ > pull.to)) {
            left.start += pull.count;
          } else {
            if ((pull.from_ < pull.to)) {
              right.end -= pull.count;
            }
          }
        }
        if (((left.length === 0) || (right.length === 0))) {
          continue;
        }
        if (this.less((right.end - 1), left.start)) {
          this.rotate(left.length, new WikiRange(left.start, right.end));
        } else {
          if (this.less(left.end, (left.end - 1))) {
            blockA = left.copy();
            firstA = new WikiRange(left.start, (left.start + (blockA.length % blockSize)));
            indexA = buffer1.start;
            index = firstA.end;
            while ((index < blockA.end)) {
              this.swap(indexA, index);
              indexA += 1;
              index += blockSize;
            }
            lastA = firstA.copy();
            lastB = new WikiRange();
            blockB = new WikiRange(right.start, (right.start + Math.min(blockSize, right.length)));
            blockA.start += firstA.length;
            indexA = buffer1.start;
            if ((buffer2.length > 0)) {
              this.blockSwap(lastA.start, buffer2.start, lastA.length);
            }
            if ((blockA.length > 0)) {
              while (true) {
                if ((((lastB.length > 0) && !(this.less((lastB.end - 1), indexA))) || (blockB.length === 0))) {
                  split = this.binaryFirst(this.read(indexA), lastB);
                  remaining = (lastB.end - split);
                  minimum = blockA.start;
                  findA = (minimum + blockSize);
                  while ((findA < blockA.end)) {
                    if (this.less(findA, minimum)) {
                      minimum = findA;
                    }
                    findA += blockSize;
                  }
                  this.blockSwap(blockA.start, minimum, blockSize);
                  this.swap(blockA.start, indexA);
                  indexA += 1;
                  if ((buffer2.length > 0)) {
                    this.mergeInternal(lastA, new WikiRange(lastA.end, split), buffer2);
                  } else {
                    this.mergeInPlace(lastA, new WikiRange(lastA.end, split));
                  }
                  if ((buffer2.length > 0)) {
                    this.blockSwap(blockA.start, buffer2.start, blockSize);
                    this.blockSwap(split, ((blockA.start + blockSize) - remaining), remaining);
                  } else {
                    this.rotate((blockA.start - split), new WikiRange(split, (blockA.start + blockSize)));
                  }
                  lastA = new WikiRange((blockA.start - remaining), ((blockA.start - remaining) + blockSize));
                  lastB = new WikiRange(lastA.end, (lastA.end + remaining));
                  blockA.start += blockSize;
                  if ((blockA.length === 0)) {
                    break;
                  }
                } else {
                  if ((blockB.length < blockSize)) {
                    this.rotate(-(blockB.length), new WikiRange(blockA.start, blockB.end));
                    lastB = new WikiRange(blockA.start, (blockA.start + blockB.length));
                    blockA.start += blockB.length;
                    blockA.end += blockB.length;
                    blockB.end = blockB.start;
                  } else {
                    this.blockSwap(blockA.start, blockB.start, blockSize);
                    lastB = new WikiRange(blockA.start, (blockA.start + blockSize));
                    blockA.start += blockSize;
                    blockA.end += blockSize;
                    blockB.start += blockSize;
                    blockB.end = Math.min((blockB.end + blockSize), right.end);
                  }
                }
              }
            }
            if ((buffer2.length > 0)) {
              this.mergeInternal(lastA, new WikiRange(lastA.end, right.end), buffer2);
            } else {
              this.mergeInPlace(lastA, new WikiRange(lastA.end, right.end));
            }
          }
        }
      }
      this.insertionSort(buffer2);
      for (const pull of pulls) {
        unique = (pull.count * 2);
        if ((pull.from_ > pull.to)) {
          buffer = new WikiRange(pull.range.start, (pull.range.start + pull.count));
          while ((buffer.length > 0)) {
            index = this.findFirstForward(this.read(buffer.start), new WikiRange(buffer.end, pull.range.end), unique);
            amount = (index - buffer.end);
            this.rotate(buffer.length, new WikiRange(buffer.start, index));
            buffer.start += (amount + 1);
            buffer.end += amount;
            unique -= 2;
          }
        } else {
          if ((pull.from_ < pull.to)) {
            buffer = new WikiRange((pull.range.end - pull.count), pull.range.end);
            while ((buffer.length > 0)) {
              index = this.findLastBackward(this.read((buffer.end - 1)), new WikiRange(pull.range.start, buffer.start), unique);
              amount = (buffer.start - index);
              this.rotate(amount, new WikiRange(index, buffer.end));
              buffer.start -= amount;
              buffer.end -= (amount + 1);
              unique -= 2;
            }
          }
        }
      }
      if (!(iterator.nextLevel())) {
        break;
      }
    }
  }
}
function sort(values) {
  new WikiSortExample(values).sort();
}
const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
