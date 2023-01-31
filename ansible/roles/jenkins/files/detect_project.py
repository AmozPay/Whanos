#!/usr/bin/python3

import os
from sys import stderr, argv

DETECTION_FILES = {
    "pom.xml": "java",
    "package.json": "javascript",
    "Makefile": "c",
    "requirements.txt": "python",
    "main.bf": "befunge"
}

def detect_language():
    files = os.listdir(".")
    detected_list = []
    for f in files:
        if os.path.isfile(f) and DETECTION_FILES.get(f):
            detected_list.append(f)
    if len(detected_list) > 1:
        print("More than 1 language configuration was detected.", file=stderr)
        exit(1)
    elif len(detected_list) < 1:
        print("No configuration was detected.", file=stderr)
        exit(1)
    print(DETECTION_FILES.get(detected_list.pop()))

def detect_docker():
    if os.path.isfile("Dockerfile"):
        print("true")
    else:
        print("false")

def detect_kubernetes():
    if os.path.isfile("whanos.yml"):
        print("true")
    else:
        print("false")

def main():
    if len(argv) < 2:
        print("Usage: ./detect_project [lang|docker|k8]", file=stderr)
        exit(1)
    switch = {
        "lang": detect_language,
        "docker": detect_docker,
        "k8": detect_kubernetes
    }
    fn = switch.get(argv[1])
    if fn is not None:
        fn()
    else:
        print("Invalid argument", file=stderr)
        exit(1)

if __name__ == "__main__":
    main()