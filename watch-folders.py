#!/usr/bin/env python3

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time
import os
import sys


class WatcherHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory:
            print(f"🆕 File added: {os.path.basename(event.src_path)}")


def main() -> int:
    try:
        watch_path = input("📁 Enter the full path to the folder you want to monitor:\n> ").strip()
    except (EOFError, KeyboardInterrupt):
        return 1

    if not os.path.isdir(watch_path):
        print(f"❌ That path doesn’t exist or isn’t a directory: {watch_path}")
        return 1

    print(f"🔍 Now watching: {watch_path}")

    event_handler = WatcherHandler()
    observer = Observer()
    observer.schedule(event_handler, path=watch_path, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    return 0


if __name__ == "__main__":
    sys.exit(main())




