// The WikiSorting source is released to the public domain under the Unlicense.

#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
typedef struct {int start,end;} WikiRange;
typedef struct {int from_,to,count;WikiRange range;} WikiPull;
typedef struct {int size,denominator,numeratorStep,decimalStep,numerator,decimal;} WikiIterator;
typedef struct {int *values,n;} WikiSortExample;
static int min_int(int a,int b){return a<b?a:b;}
static int max_int(int a,int b){return a>b?a:b;}
static WikiRange wiki_range(int start,int end){WikiRange r={start,end};return r;}
static int wiki_range_length(WikiRange r){return r.end-r.start;}
static void wiki_range_set(WikiRange *r,int start,int end){r->start=start;r->end=end;}
static WikiPull wiki_pull(int from_,int to,int count,WikiRange range){WikiPull p={from_,to,count,range};return p;}
static WikiIterator wiki_iterator_init(int size){int power=1;while(power*2<=size)power*=2;WikiIterator it={size,power/4,0,0,0,0};it.numeratorStep=size%it.denominator;it.decimalStep=size/it.denominator;return it;}
static void wiki_iterator_begin(WikiIterator *it){it->numerator=0;it->decimal=0;}
static WikiRange wiki_iterator_next_range(WikiIterator *it){int start=it->decimal;it->decimal+=it->decimalStep;it->numerator+=it->numeratorStep;if(it->numerator>=it->denominator){it->numerator-=it->denominator;it->decimal++;}return wiki_range(start,it->decimal);}
static bool wiki_iterator_finished(WikiIterator *it){return it->decimal>=it->size;}
static bool wiki_iterator_next_level(WikiIterator *it){it->decimalStep*=2;it->numeratorStep*=2;if(it->numeratorStep>=it->denominator){it->numeratorStep-=it->denominator;it->decimalStep++;}return it->decimalStep<it->size;}
static int wiki_iterator_length(WikiIterator *it){return it->decimalStep;}
static const int network4[][2] = {{0,1}, {2,3}, {0,2}, {1,3}, {1,2}};
static const int network5[][2] = {{0,1}, {3,4}, {2,4}, {2,3}, {1,4}, {0,3}, {0,2}, {1,3}, {1,2}};
static const int network6[][2] = {{1,2}, {4,5}, {0,2}, {3,5}, {0,1}, {3,4}, {2,5}, {0,3}, {1,4}, {2,4}, {1,3}, {2,3}};
static const int network7[][2] = {{1,2}, {3,4}, {5,6}, {0,2}, {3,5}, {4,6}, {0,1}, {4,5}, {2,6}, {0,4}, {1,5}, {0,3}, {2,5}, {1,3}, {2,4}, {2,3}};
static const int network8[][2] = {{0,1}, {2,3}, {4,5}, {6,7}, {0,2}, {1,3}, {4,6}, {5,7}, {1,2}, {5,6}, {0,4}, {3,7}, {1,5}, {2,6}, {1,4}, {3,6}, {2,4}, {3,5}, {3,4}};
static int read(WikiSortExample *self, int index);
static bool less(WikiSortExample *self, int left, int right);
static bool lessValues(WikiSortExample *self, int left, int right);
static bool greaterValues(WikiSortExample *self, int left, int right);
static void swap(WikiSortExample *self, int left, int right);
static int binaryFirst(WikiSortExample *self, int value, WikiRange range);
static int binaryLast(WikiSortExample *self, int value, WikiRange range);
static int findFirstForward(WikiSortExample *self, int value, WikiRange range, int unique);
static int findLastForward(WikiSortExample *self, int value, WikiRange range, int unique);
static int findFirstBackward(WikiSortExample *self, int value, WikiRange range, int unique);
static int findLastBackward(WikiSortExample *self, int value, WikiRange range, int unique);
static void insertionSort(WikiSortExample *self, WikiRange range);
static void blockSwap(WikiSortExample *self, int first, int second, int length);
static void rotate(WikiSortExample *self, int amount, WikiRange range);
static void mergeInternal(WikiSortExample *self, WikiRange left, WikiRange right, WikiRange buffer);
static void mergeInPlace(WikiSortExample *self, WikiRange originalLeft, WikiRange originalRight);
static void netSwap(WikiSortExample *self, WikiRange range, int order[8], int x, int y);
static void sortSmallRuns(WikiSortExample *self, WikiIterator *iterator);
static void sort(WikiSortExample *self);
static int read(WikiSortExample *self, int index) {
    return self->values[index];
  }
static bool less(WikiSortExample *self, int left, int right) {
    return (self->values[left] < self->values[right]);
  }
static bool lessValues(WikiSortExample *self, int left, int right) {
    return (left < right);
  }
static bool greaterValues(WikiSortExample *self, int left, int right) {
    return (left > right);
  }
static void swap(WikiSortExample *self, int left, int right) {
    { int _swap0 = self->values[right]; int _swap1 = self->values[left]; self->values[left] = _swap0; self->values[right] = _swap1; }
  }
static int binaryFirst(WikiSortExample *self, int value, WikiRange range) {
    int end;
    int middle;
    int start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((self->values[middle] < value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
static int binaryLast(WikiSortExample *self, int value, WikiRange range) {
    int end;
    int middle;
    int start;
    start = range.start;
    end = range.end;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((self->values[middle] <= value)) {
        start = (middle + 1);
      } else {
        end = middle;
      }
    }
    return start;
  }
static int findFirstForward(WikiSortExample *self, int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((wiki_range_length(range) > 0))) {
      return range.start;
    }
    skip = max_int((wiki_range_length(range) / max_int(unique, 1)), 1);
    index = (range.start + skip);
    while ((self->values[(index - 1)] < value)) {
      if ((index >= (range.end - skip))) {
        return binaryFirst(self, value, wiki_range(index, range.end));
      }
      index += skip;
    }
    return binaryFirst(self, value, wiki_range((index - skip), index));
  }
static int findLastForward(WikiSortExample *self, int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((wiki_range_length(range) > 0))) {
      return range.start;
    }
    skip = max_int((wiki_range_length(range) / max_int(unique, 1)), 1);
    index = (range.start + skip);
    while ((self->values[(index - 1)] <= value)) {
      if ((index >= (range.end - skip))) {
        return binaryLast(self, value, wiki_range(index, range.end));
      }
      index += skip;
    }
    return binaryLast(self, value, wiki_range((index - skip), index));
  }
static int findFirstBackward(WikiSortExample *self, int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((wiki_range_length(range) > 0))) {
      return range.start;
    }
    skip = max_int((wiki_range_length(range) / max_int(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (self->values[(index - 1)] >= value))) {
      if ((index < (range.start + skip))) {
        return binaryFirst(self, value, wiki_range(range.start, index));
      }
      index -= skip;
    }
    return binaryFirst(self, value, wiki_range(index, (index + skip)));
  }
static int findLastBackward(WikiSortExample *self, int value, WikiRange range, int unique) {
    int index;
    int skip;
    if (!((wiki_range_length(range) > 0))) {
      return range.start;
    }
    skip = max_int((wiki_range_length(range) / max_int(unique, 1)), 1);
    index = (range.end - skip);
    while (((index > range.start) && (self->values[(index - 1)] > value))) {
      if ((index < (range.start + skip))) {
        return binaryLast(self, value, wiki_range(range.start, index));
      }
      index -= skip;
    }
    return binaryLast(self, value, wiki_range(index, (index + skip)));
  }
static void insertionSort(WikiSortExample *self, WikiRange range) {
    int cursor;
    int destination;
    int index;
    int value;
    if (!((wiki_range_length(range) > 1))) {
      return;
    }
    for (index = (range.start + 1); index < range.end; index++) {
      value = read(self, index);
      destination = binaryLast(self, value, wiki_range(range.start, index));
      cursor = index;
      while ((cursor > destination)) {
        self->values[cursor] = read(self, (cursor - 1));
        cursor -= 1;
      }
      self->values[destination] = value;
    }
  }
static void blockSwap(WikiSortExample *self, int first, int second, int length) {
    int offset;
    if (!((length > 0))) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      swap(self, (first + offset), (second + offset));
    }
  }
static void rotate(WikiSortExample *self, int amount, WikiRange range) {
    int leftLength;
    int position;
    int rightLength;
    int split;
    if (!((wiki_range_length(range) > 0))) {
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
        blockSwap(self, position, (position + leftLength), leftLength);
        position += leftLength;
        rightLength -= leftLength;
      } else {
        blockSwap(self, ((position + leftLength) - rightLength), (position + leftLength), rightLength);
        leftLength -= rightLength;
      }
    }
  }
static void mergeInternal(WikiSortExample *self, WikiRange left, WikiRange right, WikiRange buffer) {
    int aCount;
    int bCount;
    int insert;
    aCount = 0;
    bCount = 0;
    insert = 0;
    if (((wiki_range_length(right) > 0) && (wiki_range_length(left) > 0))) {
      while (true) {
        if (!(less(self, (right.start + bCount), (buffer.start + aCount)))) {
          swap(self, (left.start + insert), (buffer.start + aCount));
          aCount += 1;
          insert += 1;
          if ((aCount >= wiki_range_length(left))) {
            break;
          }
        } else {
          swap(self, (left.start + insert), (right.start + bCount));
          bCount += 1;
          insert += 1;
          if ((bCount >= wiki_range_length(right))) {
            break;
          }
        }
      }
    }
    blockSwap(self, (buffer.start + aCount), (left.start + insert), (wiki_range_length(left) - aCount));
  }
static void mergeInPlace(WikiSortExample *self, WikiRange originalLeft, WikiRange originalRight) {
    int amount;
    WikiRange left;
    int middle;
    WikiRange right;
    if (!(((wiki_range_length(originalLeft) > 0) && (wiki_range_length(originalRight) > 0)))) {
      return;
    }
    left = originalLeft;
    right = originalRight;
    while (true) {
      middle = binaryFirst(self, read(self, left.start), right);
      amount = (middle - left.end);
      rotate(self, -(amount), wiki_range(left.start, middle));
      if ((right.end == middle)) {
        break;
      }
      right.start = middle;
      wiki_range_set(&left, (left.start + amount), right.start);
      left.start = binaryLast(self, read(self, left.start), left);
      if ((wiki_range_length(left) == 0)) {
        break;
      }
    }
  }
static void netSwap(WikiSortExample *self, WikiRange range, int order[8], int x, int y) {
    int a;
    int b;
    int first;
    int isEqual;
    int isGreater;
    int second;
    first = (range.start + x);
    second = (range.start + y);
    a = read(self, first);
    b = read(self, second);
    isGreater = greaterValues(self, a, b);
    isEqual = (!(isGreater) && !(lessValues(self, a, b)));
    if ((isGreater || (isEqual && (order[x] > order[y])))) {
      swap(self, first, second);
      { int _swap0 = order[y]; int _swap1 = order[x]; order[x] = _swap0; order[y] = _swap1; }
    }
  }
static void sortSmallRuns(WikiSortExample *self, WikiIterator *iterator) {
    while (!wiki_iterator_finished(iterator)) {
      int order[8]; for (int i=0;i<8;i++) order[i]=i;
      WikiRange range=wiki_iterator_next_range(iterator);
      const int (*pairs)[2]=NULL; int pair_count=0;
      switch(wiki_range_length(range)) {
    case 4: pairs=network4; pair_count=5; break;
    case 5: pairs=network5; pair_count=9; break;
    case 6: pairs=network6; pair_count=12; break;
    case 7: pairs=network7; pair_count=16; break;
    case 8: pairs=network8; pair_count=19; break;
      }
      for(int i=0;i<pair_count;i++) netSwap(self, range,order,pairs[i][0],pairs[i][1]);
    }
  }
static void sort(WikiSortExample *self) {
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
    WikiPull pulls[2];
    WikiRange range;
    int remaining;
    WikiRange right;
    int size;
    int split;
    int start;
    int targetBufferSize;
    int unique;
    size = self->n;
    if ((size < 4)) {
      insertionSort(self, wiki_range(0, size));
      return;
    }
    iterator = wiki_iterator_init(size);
    sortSmallRuns(self, &iterator);
    if ((size < 8)) {
      return;
    }
    while (true) {
      nominalBlock = max_int(1, (int)(sqrt(wiki_iterator_length(&iterator))));
      blockSize = nominalBlock;
      targetBufferSize = ((wiki_iterator_length(&iterator) / blockSize) + 1);
      buffer1 = wiki_range(0,0);
      buffer2 = wiki_range(0,0);
      pulls[0]=wiki_pull(0,0,0,wiki_range(0,0)); pulls[1]=wiki_pull(0,0,0,wiki_range(0,0));
      pullIndex = 0;
      find = (targetBufferSize * 2);
      findSeparately = false;
      if ((find > wiki_iterator_length(&iterator))) {
        find = targetBufferSize;
        findSeparately = true;
      }
      wiki_iterator_begin(&iterator);
      while (!(wiki_iterator_finished(&iterator))) {
        left = wiki_iterator_next_range(&iterator);
        right = wiki_iterator_next_range(&iterator);
        last = left.start;
        count = 1;
        index = last;
        while ((count < find)) {
          index = findLastForward(self, read(self, last), wiki_range((last + 1), left.end), (find - count));
          if ((index == left.end)) {
            break;
          }
          last = index;
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = wiki_pull(index, left.start, count, wiki_range(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = wiki_range(left.start, (left.start + targetBufferSize));
            buffer2 = wiki_range((left.start + targetBufferSize), (left.start + count));
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = wiki_range(left.start, (left.start + count));
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = wiki_range(left.start, (left.start + count));
                findSeparately = false;
              } else {
                buffer2 = wiki_range(left.start, (left.start + count));
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > wiki_range_length(buffer1)))) {
            buffer1 = wiki_range(left.start, (left.start + count));
            pulls[pullIndex] = wiki_pull(index, left.start, count, wiki_range(left.start, right.end));
          }
        }
        last = (right.end - 1);
        count = 1;
        while ((count < find)) {
          index = findFirstBackward(self, read(self, last), wiki_range(right.start, last), (find - count));
          if ((index == right.start)) {
            break;
          }
          last = (index - 1);
          count += 1;
        }
        index = last;
        if ((count >= targetBufferSize)) {
          pulls[pullIndex] = wiki_pull(index, right.end, count, wiki_range(left.start, right.end));
          pullIndex = 1;
          if ((count == (targetBufferSize * 2))) {
            buffer1 = wiki_range((right.end - count), (right.end - targetBufferSize));
            buffer2 = wiki_range((right.end - targetBufferSize), right.end);
            break;
          } else {
            if ((find == (targetBufferSize * 2))) {
              buffer1 = wiki_range((right.end - count), right.end);
              find = targetBufferSize;
            } else {
              if (findSeparately) {
                buffer1 = wiki_range((right.end - count), right.end);
                findSeparately = false;
              } else {
                if ((pulls[0].range.start == left.start)) {
                  pulls[0].range.end -= pulls[1].count;
                }
                buffer2 = wiki_range((right.end - count), right.end);
                break;
              }
            }
          }
        } else {
          if (((pullIndex == 0) && (count > wiki_range_length(buffer1)))) {
            buffer1 = wiki_range((right.end - count), right.end);
            pulls[pullIndex] = wiki_pull(index, right.end, count, wiki_range(left.start, right.end));
          }
        }
      }
      for (pull = 0; pull < 2; pull++) {
        length = pulls[pull].count;
        if ((pulls[pull].to < pulls[pull].from_)) {
          index = pulls[pull].from_;
          if ((length > 1)) {
            for (count = 1; count < length; count++) {
              index = findFirstBackward(self, read(self, (index - 1)), wiki_range(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count));
              range = wiki_range((index + 1), (pulls[pull].from_ + 1));
              rotate(self, (wiki_range_length(range) - count), range);
              pulls[pull].from_ = (index + count);
            }
          }
        } else {
          if ((pulls[pull].to > pulls[pull].from_)) {
            index = (pulls[pull].from_ + 1);
            if ((length > 1)) {
              for (count = 1; count < length; count++) {
                index = findLastForward(self, read(self, index), wiki_range(index, pulls[pull].to), (length - count));
                range = wiki_range(pulls[pull].from_, (index - 1));
                rotate(self, count, range);
                pulls[pull].from_ = ((index - 1) - count);
              }
            }
          }
        }
      }
      bufferSize = wiki_range_length(buffer1);
      blockSize = ((wiki_iterator_length(&iterator) / bufferSize) + 1);
      wiki_iterator_begin(&iterator);
      while (!(wiki_iterator_finished(&iterator))) {
        left = wiki_iterator_next_range(&iterator);
        right = wiki_iterator_next_range(&iterator);
        start = left.start;
        for (int pull_i=0; pull_i<2; pull_i++) {
        WikiPull pull = pulls[pull_i];
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
        if (((wiki_range_length(left) == 0) || (wiki_range_length(right) == 0))) {
          continue;
        }
        if (less(self, (right.end - 1), left.start)) {
          rotate(self, wiki_range_length(left), wiki_range(left.start, right.end));
        } else {
          if (less(self, left.end, (left.end - 1))) {
            blockA = left;
            firstA = wiki_range(left.start, (left.start + (wiki_range_length(blockA) % blockSize)));
            indexA = buffer1.start;
            index = firstA.end;
            while ((index < blockA.end)) {
              swap(self, indexA, index);
              indexA += 1;
              index += blockSize;
            }
            lastA = firstA;
            lastB = wiki_range(0,0);
            blockB = wiki_range(right.start, (right.start + min_int(blockSize, wiki_range_length(right))));
            blockA.start += wiki_range_length(firstA);
            indexA = buffer1.start;
            if ((wiki_range_length(buffer2) > 0)) {
              blockSwap(self, lastA.start, buffer2.start, wiki_range_length(lastA));
            }
            if ((wiki_range_length(blockA) > 0)) {
              while (true) {
                if ((((wiki_range_length(lastB) > 0) && !(less(self, (lastB.end - 1), indexA))) || (wiki_range_length(blockB) == 0))) {
                  split = binaryFirst(self, read(self, indexA), lastB);
                  remaining = (lastB.end - split);
                  minimum = blockA.start;
                  findA = (minimum + blockSize);
                  while ((findA < blockA.end)) {
                    if (less(self, findA, minimum)) {
                      minimum = findA;
                    }
                    findA += blockSize;
                  }
                  blockSwap(self, blockA.start, minimum, blockSize);
                  swap(self, blockA.start, indexA);
                  indexA += 1;
                  if ((wiki_range_length(buffer2) > 0)) {
                    mergeInternal(self, lastA, wiki_range(lastA.end, split), buffer2);
                  } else {
                    mergeInPlace(self, lastA, wiki_range(lastA.end, split));
                  }
                  if ((wiki_range_length(buffer2) > 0)) {
                    blockSwap(self, blockA.start, buffer2.start, blockSize);
                    blockSwap(self, split, ((blockA.start + blockSize) - remaining), remaining);
                  } else {
                    rotate(self, (blockA.start - split), wiki_range(split, (blockA.start + blockSize)));
                  }
                  lastA = wiki_range((blockA.start - remaining), ((blockA.start - remaining) + blockSize));
                  lastB = wiki_range(lastA.end, (lastA.end + remaining));
                  blockA.start += blockSize;
                  if ((wiki_range_length(blockA) == 0)) {
                    break;
                  }
                } else {
                  if ((wiki_range_length(blockB) < blockSize)) {
                    rotate(self, -(wiki_range_length(blockB)), wiki_range(blockA.start, blockB.end));
                    lastB = wiki_range(blockA.start, (blockA.start + wiki_range_length(blockB)));
                    blockA.start += wiki_range_length(blockB);
                    blockA.end += wiki_range_length(blockB);
                    blockB.end = blockB.start;
                  } else {
                    blockSwap(self, blockA.start, blockB.start, blockSize);
                    lastB = wiki_range(blockA.start, (blockA.start + blockSize));
                    blockA.start += blockSize;
                    blockA.end += blockSize;
                    blockB.start += blockSize;
                    blockB.end = min_int((blockB.end + blockSize), right.end);
                  }
                }
              }
            }
            if ((wiki_range_length(buffer2) > 0)) {
              mergeInternal(self, lastA, wiki_range(lastA.end, right.end), buffer2);
            } else {
              mergeInPlace(self, lastA, wiki_range(lastA.end, right.end));
            }
          }
        }
      }
      insertionSort(self, buffer2);
      for (int pull_i=0; pull_i<2; pull_i++) {
        WikiPull pull = pulls[pull_i];
        unique = (pull.count * 2);
        if ((pull.from_ > pull.to)) {
          buffer = wiki_range(pull.range.start, (pull.range.start + pull.count));
          while ((wiki_range_length(buffer) > 0)) {
            index = findFirstForward(self, read(self, buffer.start), wiki_range(buffer.end, pull.range.end), unique);
            amount = (index - buffer.end);
            rotate(self, wiki_range_length(buffer), wiki_range(buffer.start, index));
            buffer.start += (amount + 1);
            buffer.end += amount;
            unique -= 2;
          }
        } else {
          if ((pull.from_ < pull.to)) {
            buffer = wiki_range((pull.range.end - pull.count), pull.range.end);
            while ((wiki_range_length(buffer) > 0)) {
              index = findLastBackward(self, read(self, (buffer.end - 1)), wiki_range(pull.range.start, buffer.start), unique);
              amount = (buffer.start - index);
              rotate(self, amount, wiki_range(index, buffer.end));
              buffer.start -= amount;
              buffer.end -= (amount + 1);
              unique -= 2;
            }
          }
        }
      }
      if (!(wiki_iterator_next_level(&iterator))) {
        break;
      }
    }
  }
void wiki_sort(int *values,int length){WikiSortExample state={values,length};sort(&state);}
int main(void){int values[]={0,39,21,62,91,77,14,23,90,69,51,81,68,83,32,56};int n=(int)(sizeof(values)/sizeof(values[0]));wiki_sort(values,n);putchar('[');for(int i=0;i<n;i++)printf(i?", %d":"%d",values[i]);puts("]");}
