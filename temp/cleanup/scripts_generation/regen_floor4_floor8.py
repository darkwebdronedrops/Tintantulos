import requests, time
from pathlib import Path

API_KEY = "47c92d17756bbb65ccd08e87afad4f9f"
BASE_URL = "https://api.sunoapi.org/api/v1"
OUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/audio/music")

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

TRACKS = [
    # Floor 4 main stage — "self destructive decay of Capitalism"
    ("floor4_bazaar_main", 
     "Dark corrupt capitalist bazaar music, transactional and hollow, the sound of deals that cost souls, money changing hands in shadow, self-destructive greed, sinister merchant atmosphere, dark ambient with industrial undertones, desperate and consuming, no jazz, no smooth, no xylophone, no vocals",
     "Dark Corrupt Industrial",
     "The Curio Bazaar Main"),
    
    # Floor 8 — industrial elemental chaos, NOT Doom metal
    ("floor8_forge_main",
     "Industrial elemental forge chaos, goblin engineers scrambling, containment vessels cracking, hissing steam and clanking brass, pressure alarms, frantic but comedic-dangerous, machinery about to explode, elemental fire and water mixing, NOT heavy metal, NOT Doom, factory chaos with whimsical goblin panic, no vocals",
     "Industrial Chaos Goblin",
     "The Overclock Forge"),
]

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
    
    ok = 0
    fail = 0
    
    for track_id, prompt, style, title in TRACKS:
        if generate_track(track_id, prompt, style, title):
            ok += 1
        else:
            fail += 1
        time.sleep(3)
    
    print(f"\n\nDONE: {ok}/{len(TRACKS)} OK, {fail} failed")
