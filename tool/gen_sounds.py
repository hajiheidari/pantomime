"""Generates the game's small sound effects (mono 22 kHz WAV).

Run: python3 tool/gen_sounds.py  → writes assets/sounds/*.wav
Synthesized here so there are no licensing questions.
"""
import math
import struct
import wave

RATE = 22050


def tone(freq, dur, vol=0.5, shape="sine", attack=0.005, release=0.08, slide=0.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq + slide * (t / dur)
        phase += 2 * math.pi * f / RATE
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "square":
            s = 0.6 if math.sin(phase) >= 0 else -0.6
        else:  # triangle
            s = 2 / math.pi * math.asin(math.sin(phase))
        env = min(1.0, t / attack) if attack else 1.0
        env *= min(1.0, (dur - t) / release) if release else 1.0
        out.append(s * env * vol)
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def write(name, samples):
    with wave.open(f"assets/sounds/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples)
        )


# Bright two-note "ding ding" (C6 → G6)
write("correct", tone(1047, 0.09, 0.45, "triangle") + tone(1568, 0.22, 0.45, "triangle", release=0.18))
# Downward "whoop"
write("pass", tone(520, 0.22, 0.4, "triangle", slide=-260, release=0.1))
# Short wood-block click for the last 10 seconds
write("tick", tone(1800, 0.035, 0.35, "sine", attack=0.001, release=0.03))
# Countdown beep and higher "go" beep
write("count", tone(660, 0.14, 0.4, "square", release=0.05))
write("go", tone(1320, 0.3, 0.4, "square", release=0.12))
# Round end: descending buzzer "wah wah"
write(
    "round_end",
    tone(392, 0.22, 0.35, "square", release=0.06)
    + silence(0.03)
    + tone(330, 0.22, 0.35, "square", release=0.06)
    + silence(0.03)
    + tone(262, 0.45, 0.35, "square", slide=-30, release=0.25),
)
# Victory fanfare (C-E-G-C)
write(
    "win",
    tone(523, 0.12, 0.4, "triangle")
    + tone(659, 0.12, 0.4, "triangle")
    + tone(784, 0.12, 0.4, "triangle")
    + mix(tone(1047, 0.5, 0.35, "triangle", release=0.3), tone(784, 0.5, 0.2, "triangle", release=0.3)),
)
