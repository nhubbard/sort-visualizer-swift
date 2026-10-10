// The WikiSorting source is released to the public domain under the Unlicense.

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <tuple>
#include <utility>
#include <vector>

struct WikiRange {
  int start, end;
  WikiRange(int start=0,int end=0):start(start),end(end){}
  int length() const { return end-start; }
  void set(int first,int last){start=first;end=last;}
  WikiRange copy() const { return *this; }
};
struct WikiPull {
  int from_,to,count;
  WikiRange range;
  WikiPull(int from_=0,int to=0,int count=0,WikiRange range=WikiRange()):from_(from_),to(to),count(count),range(range){}
};
struct WikiIterator {
  int size,denominator,numeratorStep,decimalStep,numerator,decimal;
  WikiIterator(int size=8):size(size),numerator(0),decimal(0){
    int power=1;while(power*2<=size)power*=2;
    denominator=power/4;numeratorStep=size%denominator;decimalStep=size/denominator;
  }
  void begin(){numerator=0;decimal=0;}
  WikiRange nextRange(){int start=decimal;decimal+=decimalStep;numerator+=numeratorStep;if(numerator>=denominator){numerator-=denominator;decimal++;}return WikiRange(start,decimal);}
  bool finished() const{return decimal>=size;}
  bool nextLevel(){decimalStep*=2;numeratorStep*=2;if(numeratorStep>=denominator){numeratorStep-=denominator;decimalStep++;}return decimalStep<size;}
  int length() const{return decimalStep;}
};

class WikiSortExample {
public:
  int* values;
  int n;
  WikiSortExample(int* input, int count) {
    n = count;
    values = input;
  }
  int read(int index) {
    return values[index];
  }
  bool less(int left, int right) {
    return (values[left] < values[right]);
  }
  bool lessValues(int left, int right) {
    return (left < right);
  }
  bool greaterValues(int left, int right) {
    return (left > right);
  }
  void swap(int left, int right) {
    std::tie(values[left], values[right]) = std::make_tuple(values[right], values[left]);
  }
  int binaryFirst(int value, WikiRange range) {
    int end;
    int middle;
    int start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((values[middle] < value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  int binaryLast(int value, WikiRange range) {
    int end;
    int middle;
    int start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((values[middle] <= value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
  int findFirstForward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = std::max((range.length() / std::max(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] < value)) {
      if ((index >= (range.end - skip))) {
        return binaryFirst(value, WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryFirst(value, WikiRange((index - skip), index));
  }
  int findLastForward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = std::max((range.length() / std::max(unique, 1)), 1);
    index = (range.start + skip);
    while ((values[(index - 1)] <= value)) {
      if ((index >= (range.end - skip))) {
        return binaryLast(value, WikiRange(index, range.end));
      }
      index += skip;
    }
    return binaryLast(value, WikiRange((index - skip), index));
  }
  int findFirstBackward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = std::max((range.length() / std::max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] >= value))) {
      if ((index < (range.start + skip))) {
        return binaryFirst(value, WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryFirst(value, WikiRange(index, (index + skip)));
  }
  int findLastBackward(int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((range.length() > 0))) {
      return range.start;
    }
    skip = std::max((range.length() / std::max(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (values[(index - 1)] > value))) {
      if ((index < (range.start + skip))) {
        return binaryLast(value, WikiRange(range.start, index));
      }
      index -= skip;
    }
    return binaryLast(value, WikiRange(index, (index + skip)));
  }
  void insertionSort(WikiRange range) {
    int cursor;
    int destination;
    int index;
    int value;
    if (!((range.length() > 1))) {
      return;
    }
    for (index = (range.start + 1); index < range.end; index++) {
      value = read(index);
      destination = binaryLast(value, WikiRange(range.start, index));
      cursor = index;
      while ((cursor > destination)) {
        values[cursor] = read((cursor - 1));
        cursor -= 1;
      }
      values[destination] = value;
    }
  }
  void blockSwap(int first, int second, int length) {
    int offset;
    if (!((length > 0))) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      swap((first + offset), (second + offset));
    }
  }
  void rotate(int amount, WikiRange range) {
    int leftLength;
    int position;
    int rightLength;
    int split;
    if (!((range.length() > 0))) {
      return;
    }
    split = ((amount >= 0) ? (range.start + amount) : (range.end + amount));
    if (!(((range.start < split) && (split < range.end)))) {
      return;
    }
    position = range.start;
    leftLength = (split - range.start);
    rightLength = (range.end - split);
    while (((leftLength != 0) && (rightLength != 0))) {
      if ((leftLength <= rightLength)) {
        blockSwap(position, (position + leftLength), leftLength);
        position += leftLength;
        rightLength -= leftLength;
      } else {
        blockSwap(((position + leftLength) - rightLength), (position + leftLength), rightLength);
        leftLength -= rightLength;
      }
    }
  }
  void mergeInternal(WikiRange left, WikiRange right, WikiRange buffer) {
    int aCount;
    int bCount;
    int insert;
    aCount = 0;
    bCount = 0;
    insert = 0;
    if (((right.length() > 0) && (left.length() > 0))) {
      while (true) {
        if (!(less((right.start + bCount), (buffer.start + aCount)))) {
          swap((left.start + insert), (buffer.start + aCount));
          aCount += 1;
          insert += 1;
          if ((aCount >= left.length())) {
            break;
          }
        } else {
          swap((left.start + insert), (right.start + bCount));
          bCount += 1;
          insert += 1;
          if ((bCount >= right.length())) {
            break;
          }
        }
      }
    }
    blockSwap((buffer.start + aCount), (left.start + insert), (left.length() - aCount));
  }
  void mergeInPlace(WikiRange originalLeft, WikiRange originalRight) {
    int amount;
    WikiRange left;
    int middle;
    WikiRange right;
    if (!(((originalLeft.length() > 0) && (originalRight.length() > 0)))) {
      return;
    }
    left = originalLeft;
    right = originalRight;
    while (true) {
      middle = binaryFirst(read(left.start), right);
      amount = (middle - left.end);
      rotate(-(amount), WikiRange(left.start, middle));
      if ((right.end == middle)) {
        break;
      }
      right.start = middle;
      left.set((left.start + amount), right.start);
      left.start = binaryLast(read(left.start), left);
      if ((left.length() == 0)) {
        break;
      }
    }
  }
  void netSwap(WikiRange range, std::array<int,8>& order, int x, int y) {
    int a;
    int b;
    int first;
    int isEqual;
    int isGreater;
    int second;
    first = (range.start + x);
    second = (range.start + y);
    a = read(first);
    b = read(second);
    isGreater = greaterValues(a, b);
    isEqual = (!(isGreater) && !(lessValues(a, b)));
    if ((isGreater || (isEqual && (order[x] > order[y])))) {
      swap(first, second);
      std::tie(order[x], order[y]) = std::make_tuple(order[y], order[x]);
    }
  }
  void sortSmallRuns(WikiIterator& iterator) {
    std::array<int,8> order;
    std::vector<std::pair<int,int>> pairs;
    WikiRange range;
    int x;
    int y;
    while (!(iterator.finished())) {
      order = std::array<int, 8>{0,1,2,3,4,5,6,7};
      range = iterator.nextRange();
      pairs = {};
      if ((range.length() == 8)) {
        pairs = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {1, 2}, {5, 6}, {0, 4}, {3, 7}, {1, 5}, {2, 6}, {1, 4}, {3, 6}, {2, 4}, {3, 5}, {3, 4}};
      } else {
        if ((range.length() == 7)) {
          pairs = {{1, 2}, {3, 4}, {5, 6}, {0, 2}, {3, 5}, {4, 6}, {0, 1}, {4, 5}, {2, 6}, {0, 4}, {1, 5}, {0, 3}, {2, 5}, {1, 3}, {2, 4}, {2, 3}};
        } else {
          if ((range.length() == 6)) {
            pairs = {{1, 2}, {4, 5}, {0, 2}, {3, 5}, {0, 1}, {3, 4}, {2, 5}, {0, 3}, {1, 4}, {2, 4}, {1, 3}, {2, 3}};
          } else {
            if ((range.length() == 5)) {
              pairs = {{0, 1}, {3, 4}, {2, 4}, {2, 3}, {1, 4}, {0, 3}, {0, 2}, {1, 3}, {1, 2}};
            } else {
              if ((range.length() == 4)) {
                pairs = {{0, 1}, {2, 3}, {0, 2}, {1, 3}, {1, 2}};
              } else {
                pairs = {};
              }
            }
          }
        }
      }
      for (auto [x, y] : pairs) {
        netSwap(range, order, x, y);
      }
    }
  }
  void sort() {
    int amount;
    WikiRange blockA;
    WikiRange blockB;
    int blockSize;
    WikiRange buffer;
    WikiRange buffer1;
    WikiRange buffer2;
    int bufferSize;
    int count;
    int find;
    int findA;
    bool findSeparately;
    WikiRange firstA;
    int index;
    int indexA;
    WikiIterator iterator;
    int last;
    WikiRange lastA;
    WikiRange lastB;
    WikiRange left;
    int length;
    int minimum;
    int nominalBlock;
    int pull;
    int pullIndex;
    std::array<WikiPull,2> pulls;
    WikiRange range;
    int remaining;
    WikiRange right;
    int size;
    int split;
    int start;
    int targetBufferSize;
    int unique;
    size = n;
    if ((size < 4)) {
      insertionSort(WikiRange(0, size));
      return;
    }
    iterator = WikiIterator(size);
    sortSmallRuns(iterator);
    if ((size < 8)) {
      return;
    }
    while (true) {
      nominalBlock = std::max(1, int(std::sqrt(iterator.length())));
      blockSize = nominalBlock;
      targetBufferSize = ((iterator.length() / blockSize) + 1);
      buffer1 = WikiRange();
      buffer2 = WikiRange();
      pulls = {WikiPull(), WikiPull()};
      pullIndex = 0;
      find = (targetBufferSize * 2);
      findSeparately = false;
      if ((find > iterator.length())) {
        find = targetBufferSize;
        findSeparately = true;
      }
      iterator.begin();
      while (!(iterator.finished())) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        last = left.start;
        count = 1;
        index = last;
        while ((count < find)) {
          index = findLastForward(read(last), WikiRange((last + 1), left.end), (find - count));
          if ((index == left.end)) {
            break;
          }
          last = index;
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = WikiPull(index, left.start, count, WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = WikiRange(left.start, (left.start + targetBufferSize));
            buffer2 = WikiRange((left.start + targetBufferSize), (left.start + count));
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = WikiRange(left.start, (left.start + count));
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = WikiRange(left.start, (left.start + count));
                findSeparately = false;
              } else {
                buffer2 = WikiRange(left.start, (left.start + count));
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = WikiRange(left.start, (left.start + count));
            pulls[pullIndex] = WikiPull(index, left.start, count, WikiRange(left.start, right.end));
          }
        }
        last = (right.end - 1);
        count = 1;
        while ((count < find)) {
          index = findFirstBackward(read(last), WikiRange(right.start, last), (find - count));
          if ((index == right.start)) {
            break;
          }
          last = (index - 1);
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = WikiPull(index, right.end, count, WikiRange(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = WikiRange((right.end - count), (right.end - targetBufferSize));
            buffer2 = WikiRange((right.end - targetBufferSize), right.end);
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = WikiRange((right.end - count), right.end);
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = WikiRange((right.end - count), right.end);
                findSeparately = false;
              } else {
                if ((pulls[0].range.start == left.start)) {
                  pulls[0].range.end -= pulls[1].count;
                }
                buffer2 = WikiRange((right.end - count), right.end);
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > buffer1.length()))) {
            buffer1 = WikiRange((right.end - count), right.end);
            pulls[pullIndex] = WikiPull(index, right.end, count, WikiRange(left.start, right.end));
          }
        }
      }
      for (pull = 0; pull < 2; pull++) {
        length = pulls[pull].count;
        if ((pulls[pull].to < pulls[pull].from_)) {
          index = pulls[pull].from_;
          if ((length > 1)) {
            for (count = 1; count < length; count++) {
              index = findFirstBackward(read((index - 1)), WikiRange(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count));
              range = WikiRange((index + 1), (pulls[pull].from_ + 1));
              rotate((range.length() - count), range);
              pulls[pull].from_ = (index + count);
            }
          }
        } else {
          if ((pulls[pull].to > pulls[pull].from_)) {
            index = (pulls[pull].from_ + 1);
            if ((length > 1)) {
              for (count = 1; count < length; count++) {
                index = findLastForward(read(index), WikiRange(index, pulls[pull].to), (length - count));
                range = WikiRange(pulls[pull].from_, (index - 1));
                rotate(count, range);
                pulls[pull].from_ = ((index - 1) - count);
              }
            }
          }
        }
      }
      bufferSize = buffer1.length();
      blockSize = ((iterator.length() / bufferSize) + 1);
      iterator.begin();
      while (!(iterator.finished())) {
        left = iterator.nextRange();
        right = iterator.nextRange();
        start = left.start;
        for (const auto& pull : pulls) {
          if ((start != pull.range.start)) {
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
        if (((left.length() == 0) || (right.length() == 0))) {
          continue;
        }
        if (less((right.end - 1), left.start)) {
          rotate(left.length(), WikiRange(left.start, right.end));
        } else {
          if (less(left.end, (left.end - 1))) {
            blockA = left.copy();
            firstA = WikiRange(left.start, (left.start + (blockA.length() % blockSize)));
            indexA = buffer1.start;
            index = firstA.end;
            while ((index < blockA.end)) {
              swap(indexA, index);
              indexA += 1;
              index += blockSize;
            }
            lastA = firstA.copy();
            lastB = WikiRange();
            blockB = WikiRange(right.start, (right.start + std::min(blockSize, right.length())));
            blockA.start += firstA.length();
            indexA = buffer1.start;
            if ((buffer2.length() > 0)) {
              blockSwap(lastA.start, buffer2.start, lastA.length());
            }
            if ((blockA.length() > 0)) {
              while (true) {
                if ((((lastB.length() > 0) && !(less((lastB.end - 1), indexA))) || (blockB.length() == 0))) {
                  split = binaryFirst(read(indexA), lastB);
                  remaining = (lastB.end - split);
                  minimum = blockA.start;
                  findA = (minimum + blockSize);
                  while ((findA < blockA.end)) {
                    if (less(findA, minimum)) {
                      minimum = findA;
                    }
                    findA += blockSize;
                  }
                  blockSwap(blockA.start, minimum, blockSize);
                  swap(blockA.start, indexA);
                  indexA += 1;
                  if ((buffer2.length() > 0)) {
                    mergeInternal(lastA, WikiRange(lastA.end, split), buffer2);
                  } else {
                    mergeInPlace(lastA, WikiRange(lastA.end, split));
                  }
                  if ((buffer2.length() > 0)) {
                    blockSwap(blockA.start, buffer2.start, blockSize);
                    blockSwap(split, ((blockA.start + blockSize) - remaining), remaining);
                  } else {
                    rotate((blockA.start - split), WikiRange(split, (blockA.start + blockSize)));
                  }
                  lastA = WikiRange((blockA.start - remaining), ((blockA.start - remaining) + blockSize));
                  lastB = WikiRange(lastA.end, (lastA.end + remaining));
                  blockA.start += blockSize;
                  if ((blockA.length() == 0)) {
                    break;
                  }
                } else {
                  if ((blockB.length() < blockSize)) {
                    rotate(-(blockB.length()), WikiRange(blockA.start, blockB.end));
                    lastB = WikiRange(blockA.start, (blockA.start + blockB.length()));
                    blockA.start += blockB.length();
                    blockA.end += blockB.length();
                    blockB.end = blockB.start;
                  } else {
                    blockSwap(blockA.start, blockB.start, blockSize);
                    lastB = WikiRange(blockA.start, (blockA.start + blockSize));
                    blockA.start += blockSize;
                    blockA.end += blockSize;
                    blockB.start += blockSize;
                    blockB.end = std::min((blockB.end + blockSize), right.end);
                  }
                }
              }
            }
            if ((buffer2.length() > 0)) {
              mergeInternal(lastA, WikiRange(lastA.end, right.end), buffer2);
            } else {
              mergeInPlace(lastA, WikiRange(lastA.end, right.end));
            }
          }
        }
      }
      insertionSort(buffer2);
      for (const auto& pull : pulls) {
        unique = (pull.count * 2);
        if ((pull.from_ > pull.to)) {
          buffer = WikiRange(pull.range.start, (pull.range.start + pull.count));
          while ((buffer.length() > 0)) {
            index = findFirstForward(read(buffer.start), WikiRange(buffer.end, pull.range.end), unique);
            amount = (index - buffer.end);
            rotate(buffer.length(), WikiRange(buffer.start, index));
            buffer.start += (amount + 1);
            buffer.end += amount;
            unique -= 2;
          }
        } else {
          if ((pull.from_ < pull.to)) {
            buffer = WikiRange((pull.range.end - pull.count), pull.range.end);
            while ((buffer.length() > 0)) {
              index = findLastBackward(read((buffer.end - 1)), WikiRange(pull.range.start, buffer.start), unique);
              amount = (buffer.start - index);
              rotate(amount, WikiRange(index, buffer.end));
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
};

void wiki_sort(int* values, int length) { WikiSortExample(values,length).sort(); }
int main(){std::vector<int> values={0,39,21,62,91,77,14,23,90,69,51,81,68,83,32,56};wiki_sort(values.data(),(int)values.size());std::cout<<"[";for(size_t i=0;i<values.size();i++){if(i)std::cout<<", ";std::cout<<values[i];}std::cout<<"]\n";}
