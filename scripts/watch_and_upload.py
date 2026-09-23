import time
import os
from dotenv import load_dotenv
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import requests

load_dotenv()

DATABRICKS_WORKSPACE = "https://dbc-a00383b0-a537.cloud.databricks.com" 
DATABRICKS_TOKEN     = os.environ["DATABRICKS_TOKEN"]              
VOLUME_PATH          = "/Volumes/data_mart/source/my_volume" 
WATCH_FOLDER         = "C:/Users/KARTHICKKUMAR.A/Downloads/BIZ/files"

def wait_for_file(filepath):
    time.sleep(5)                                   # ← wait 5 seconds first
    attempts = 0
    while attempts < 10:
        try:
            with open(filepath, "rb") as f:
                f.read(1)                           # ← try to actually read it
            print("✅ File is ready!")
            return True
        except PermissionError:
            attempts += 1
            print(f"⏳ File not ready... attempt {attempts}/10")
            time.sleep(3)
    print("❌ Could not access file after 10 attempts")
    return False

def upload_to_databricks(filepath):
    filename = os.path.basename(filepath)
    
    url = f"{DATABRICKS_WORKSPACE}/api/2.0/fs/files{VOLUME_PATH}/{filename}"

    """ The f before the quote tells Python: "look inside the curly braces {} 
    and replace them with the actual variable value."""
    
    print(f"📤 Uploading to: {url}")   # ← add this to see exact URL being called
    
    with open(filepath, "rb") as f:
        response = requests.put(
            url,
            headers={
                "Authorization": f"Bearer {DATABRICKS_TOKEN}",
                "Content-Type": "application/octet-stream"   # ← add this header
            },
            data=f
        ) 
        """ os.path.basename(filepath) strips the folder path and gives you just the filename 
        — e.g. C:/Users/.../sales_jan.csv becomes sales_jan.csv. 
        requests is like a courier company.put() means:
        "Take this file and place it at this exact location."
        
        """
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")   # ← show full response
    
    if response.status_code in (200,204):
        print(f"✅ Uploaded successfully: {filename}")
    else:
        print(f"❌ Upload failed: {response.status_code} - {response.text}")

class NewFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith('.csv'):
            print(f"📁 New file detected: {event.src_path}")
            if wait_for_file(event.src_path):       # ← wait THEN upload
                upload_to_databricks(event.src_path)

observer = Observer()
observer.schedule(NewFileHandler(), path=WATCH_FOLDER, recursive=False)
observer.start()

"""watchdog is a Python library that hooks into the OS-level file system events. 
FileSystemEventHandler is the base class — you override on_created to define what happens when a new file appears. 
recursive=False means it only watches the top-level folder, not subfolders. 
The observer.start() runs it in a background thread — 
that's why the while True: time.sleep(5) loop at the bottom exists, 
just to keep the main thread alive """

""" The main thread does literally nothing useful here. 
It just sleeps in a loop. Its only job is to exist — because Python has a rule:
When the main thread dies, the entire program exits — 
and takes every background thread with it. """


print(f"👀 Watching folder: {WATCH_FOLDER}")
print("Drop a CSV file to auto-upload to Databricks Volume...")

try:
    while True:
        time.sleep(5)
except KeyboardInterrupt:
    observer.stop()

observer.join()

""" The observer.join() at the end is important — 
without it, if you hit Ctrl+C while an upload is mid-flight, 
the program would exit abruptly
 and the file might be partially uploaded to Databricks. """


"""we are doing this just to prevent if there is any keyboad interrup 
befor the files reads complete fully ,
 the file should be read fully even if there is a keyboad interrupt """