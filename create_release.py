import sys
import os
import shutil
import zipfile
import re

directories = {'.'}


class Node:
    def __init__(self, value):
        self.value = value
        self.next = None

class Stack:

    # Initializing a stack.
    # Use a dummy node, which is
    # easier for handling edge cases.
    def __init__(self):
        self.head = Node("head")
        self.size = 0

    # String representation of the stack
    def __str__(self):
        cur = self.head.next
        out = ""
        while cur:
            out += str(cur.value) + "->"
            cur = cur.next
        return out[:-2]

    # Get the current size of the stack
    def getSize(self):
        return self.size

    # Check if the stack is empty
    def isEmpty(self):
        return self.size == 0

    # Get the top item of the stack
    def peek(self):

        # Sanitary check to see if we
        # are peeking an empty stack.
        if self.isEmpty():
            return None

        return self.head.next.value

    # Push a value into the stack.
    def push(self, value):
        node = Node(value)
        node.next = self.head.next  # Make the new node point to the current head
        self.head.next = node  # !!! # Update the head to be the new node
        self.size += 1

    # Remove a value from the stack and return.

    def pop(self):
        if self.isEmpty():
            raise Exception("Popping from an empty stack")
        remove = self.head.next
        self.head.next = remove.next  # !!! changed
        self.size -= 1
        return remove.value


def open_file(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()
    except:
        return None


def write_file(file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)


def parse_cmake_file(cmake_file, current_dir):
    final_cmake = ''
    for line in cmake_file.split('\n'):
        if 'add_subdirectory' in line:
            if 'KEEP THIS' in line:
                final_cmake += line + '\n'
                continue
            substr = re.findall(r'\((.*?)\)', line)
            current_dir.push(os.path.join(current_dir.peek(), substr[0]))
            final_cmake += parse_cmake_file(open_file(os.path.join(
                current_dir.peek(), 'CMakeLists.txt')), current_dir)
            current_dir.pop()
        elif 'include' in line:
            substr = re.findall(r'\((.*?)\)', line)
            new_cmake_file = open_file(
                os.path.join(current_dir.peek(), substr[0]))
            if new_cmake_file is None:
                final_cmake += line + '\n'
            else:
                final_cmake += parse_cmake_file(new_cmake_file, current_dir)
        else:
            final_cmake += line + '\n'

    return final_cmake


def create_release(dir_path=None):
    main_cmake = open_file(os.path.join(dir_path, 'CMakeLists.txt'))
    current_dir = Stack()
    current_dir.push(dir_path)
    final_cmake = parse_cmake_file(main_cmake, current_dir)
    write_file('./bits.cmake', final_cmake)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        create_release(sys.argv[1])
    else:
        create_release('.')
