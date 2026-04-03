/*
 * Ring Buffer (Circular Buffer) Implementation
 * Template class for storing fixed-size data with automatic overwrite
 */

#ifndef RING_BUFFER_H
#define RING_BUFFER_H

template <typename T, size_t N>
class RingBuffer {
private:
  T      buffer[N];     // Fixed-size array
  size_t writeIndex;    // Write position (next write location)
  size_t readIndex;     // Read position (oldest data)
  size_t count;         // Current number of elements
  bool   isFull;        // Buffer full flag

public:
  // Constructor
  RingBuffer() : writeIndex(0), readIndex(0), count(0), isFull(false) {}

  // Push data to buffer (overwrites oldest if full)
  void push(const T &item) {
    buffer[writeIndex] = item;

    if (isFull) {
      readIndex = (readIndex + 1) % N;  // Advance read index when overwriting
    }

    writeIndex = (writeIndex + 1) % N;

    if (writeIndex == readIndex) {
      isFull = true;
      count  = N;   // Buffer is exactly full; fix: set count to N
    } else if (count < N) {
      count++;
    }
  }

  // Pop oldest data from buffer
  T pop() {
    if (isEmpty()) {
      return T();
    }

    T item    = buffer[readIndex];
    readIndex = (readIndex + 1) % N;
    isFull    = false;
    count--;

    return item;
  }

  // Peek at oldest data without removing
  T peek() const {
    if (isEmpty()) {
      return T();
    }
    return buffer[readIndex];
  }

  // Get item at specific index (0 = oldest)
  T get(size_t index) const {
    if (index >= count) {
      return T();
    }
    size_t actualIndex = (readIndex + index) % N;
    return buffer[actualIndex];
  }

  // Check if buffer is empty
  bool isEmpty() const {
    return (!isFull && (writeIndex == readIndex));
  }

  // Check if buffer is full
  bool full() const {
    return isFull;
  }

  // Get current number of elements
  size_t size() const {
    return count;
  }

  // Get maximum capacity
  size_t capacity() const {
    return N;
  }

  // Clear all data
  void clear() {
    writeIndex = 0;
    readIndex  = 0;
    count      = 0;
    isFull     = false;
  }

  // Get buffer utilization percentage
  float utilization() const {
    return (float)count / (float)N * 100.0f;
  }
};

#endif // RING_BUFFER_H
