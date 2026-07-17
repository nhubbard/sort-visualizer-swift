import java.util.Arrays;

public class pigeonholesort {
  public static int[] sort(int arr[]) {
    int min = arr[0];
    int max = arr[0];
    for (int i = 1; i < arr.length; i++) {
      if (arr[i] < min) {min = arr[i];}
      if (arr[i] > max) {max = arr[i];}
    }

    int size = max - min + 1;
    int[] holes = new int[size];
    for (int value : arr) {
      holes[value - min]++;
    }

    int[] output = new int[arr.length];
    int j = 0;
    for (int count = 0; count < size; count++) {
      while (holes[count] > 0) {
        holes[count]--;
        output[j] = count + min;
        j++;
      }
    }
    return output;
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    array = sort(array);
    System.out.println(Arrays.toString(array));
  }
}
