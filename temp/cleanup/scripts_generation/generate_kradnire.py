import requests, time
from pathlib import Path

API_KEY = "47c92d17756bbb65ccd08e87afad4f9f"
BASE_URL = "https://api.sunoapi.org/api/v1"
OUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/audio/music")

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

def generate_track(track_id, prompt, style, title):
    print(f"\n[{track_id}] Generating: {title}")
    
    resp = requests.post(
        f"{BASE_URL}/generate",
        headers=HEADERS,
        json={
            "customMode": True,
            "instrumental": True,
            "model": "V4_5ALL",
            "prompt": prompt,
            "style": style,
            "title": title,
            "callBackUrl": "https://httpbin.org/post"
        },
        timeout=30
    )
    
    if resp.status_code != 200:
        print(f"  FAILED: HTTP {resp.status_code}")
        return False
    
    data = resp.json()
    if data.get("code") != 200:
        print(f"  FAILED: {data.get('msg')}")
        return False
    
    task_id = data["data"]["taskId"]
    print(f"  Task ID: {task_id}")
    
    for i in range(40):
        time.sleep(15)
        
        status_resp = requests.get(
            f"{BASE_URL}/generate/record-info?taskId={task_id}",
            headers={"Authorization": f"Bearer {API_KEY}"},
            timeout=10
        )
        
        status_data = status_resp.json()
        status = status_data.get("data", {}).get("status", "UNKNOWN")
        print(f"  [{i+1}/40] Status: {status}", end="\r")
        
        if status == "SUCCESS":
            tracks = status_data.get("data", {}).get("response", {}).get("sunoData", [])
            for idx, t in enumerate(tracks):
                audio_url = t.get("audioUrl")
                duration = t.get("duration", 0)
                if audio_url:
                    audio_resp = requests.get(audio_url, timeout=30)
                    if audio_resp.status_code == 200:
                        suffix = f"_v{idx+1}" if len(tracks) > 1 else ""
                        out_path = OUT / f"{track_id}{suffix}.mp3"
                        out_path.write_bytes(audio_resp.content)
                        print(f"\n  ✅ SAVED: {track_id}{suffix}.mp3 ({duration:.1f}s)")
            return True
        elif status == "FAILED":
            print(f"\n  FAILED: Generation error")
            return False
    
    print(f"\n  TIMEOUT")
    return False

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    
    # Kradnire — Elemental Dragon Lord of Air
    # Wind, majesty, hope, sacrifice, rabbit transformation, flirty wink
    generate_track(
        "kradnire_theme",
        "Majestic soaring elemental dragon lord of air theme, powerful wind orchestra, sweeping harp and flute melodies, themes of sacrifice and transformation, once a rabbit who gave everything to escape an infinite maze, now an apex predator of wind and sky, hopeful and triumphant despite loss, a playful flirty wink in the melody, soaring brass, ethereal strings, not dark, not menacing, beautiful and powerful, no vocals",
        "Epic Orchestral Wind",
        "Kradnire - Dragon Lord of Air"
    )
