#!/usr/bin/env python3
"""Render Kevin-style clean card PNGs + dump animator coords.

Geometry is traced from the clean no-star card drawings (23/26 flip pair,
38 overload first down, then 68/2/19/6). Same numbers feed plays.html.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Animator / logical field
FW, FH = 360, 500
LOS = 300
OUT = Path(__file__).resolve().parent

# Render at 2x for crisp Playbook PNGs
SCALE = 2
CW, CH = FW * SCALE, (FH + 48) * SCALE  # + header

COLORS = {
    "Q": (215, 38, 61),
    "C": (61, 61, 61),
    "X": (240, 140, 0),
    "A": (27, 108, 168),
    "B": (108, 117, 125),
    "Y": (111, 66, 193),
    "Z": (18, 184, 134),
}
DEF_FILL = (74, 74, 74)


def flipx(x: float) -> float:
    return FW - x


def flipp(p):
    return {"x": flipx(p["x"]), "y": p["y"]}


def flips(s):
    return {**s, "x": flipx(s["x"]), "route": [flipp(p) for p in s.get("route", [])]}


def spot(letter, x, y, route=None, **extra):
    return {"letter": letter, "x": x, "y": y, "route": route or [], **extra}


COVER3 = [
    {"id": "C", "x": 42, "y": 255},
    {"id": "C", "x": 318, "y": 255},
    {"id": "LB", "x": 135, "y": 275},
    {"id": "LB", "x": 225, "y": 275},
    {"id": "SS", "x": 85, "y": 145},
    {"id": "S", "x": 180, "y": 125},
    {"id": "FS", "x": 275, "y": 145},
]
NICKEL = [
    {"id": "C", "x": 40, "y": 248},
    {"id": "C", "x": 320, "y": 248},
    {"id": "LB", "x": 115, "y": 268},
    {"id": "LB", "x": 180, "y": 268},
    {"id": "LB", "x": 245, "y": 268},
    {"id": "SS", "x": 85, "y": 175},
    {"id": "FS", "x": 180, "y": 140},
]

# --- Traced from clean cards ---
# 26 Post Corner Right (source). 23 = true horizontal flip.
P26 = {
    "num": "26",
    "title": "Post Corner Right",
    "defense": COVER3,
    "spots": [
        # Q rolls forward-right to open circle (not a sideline scramble)
        spot("Q", 180, 345, [{"x": 275, "y": 245}]),
        spot("C", 180, LOS, []),
        # X short out
        spot("X", 62, 308, [{"x": 28, "y": 262}]),
        # A dig: up then 90° in
        spot("A", 112, 305, [{"x": 112, "y": 235}, {"x": 185, "y": 235}]),
        # B zig: up, left across C, then right to open circle
        spot("B", 212, 320, [{"x": 212, "y": 278}, {"x": 155, "y": 278}, {"x": 295, "y": 278}]),
        # Y corner
        spot("Y", 252, 305, [{"x": 252, "y": 235}, {"x": 318, "y": 175}]),
        # Z post: diagonal deep left, crosses Y
        spot("Z", 318, 308, [{"x": 195, "y": 165}]),
    ],
}
P23 = {
    "num": "23",
    "title": "Post Corner Right flipped",
    "defense": [{**d, "x": flipx(d["x"])} for d in COVER3],
    "spots": [flips(s) for s in P26["spots"]],
    # C engagement triangle on the card (short nudge toward LB) — keep C still for animation
}
P38 = {
    "num": "38",
    "title": "Overload first down",
    "defense": NICKEL,
    "spots": [
        # Card shows red Q circle (no path). Animator uses named circle, not star.
        spot("Q", 180, 348, []),
        spot("C", 172, LOS, [{"x": 172, "y": 278}, {"x": 210, "y": 278}]),
        spot("A", 122, LOS, [{"x": 122, "y": 255}, {"x": 135, "y": 240}, {"x": 55, "y": 165}]),
        # X is the red path on the card: up then break up-right
        spot("X", 205, LOS, [{"x": 205, "y": 215}, {"x": 265, "y": 165}]),
        spot("B", 240, LOS, [{"x": 240, "y": 255}, {"x": 275, "y": 235}, {"x": 250, "y": 225}]),
        spot("Y", 278, LOS, [{"x": 278, "y": 275}, {"x": 310, "y": 255}, {"x": 340, "y": 255}]),
        spot("Z", 315, LOS, [{"x": 250, "y": 245}, {"x": 255, "y": 200}, {"x": 325, "y": 145}]),
    ],
}
P68 = {
    "num": "68",
    "title": "Rice Touchdown play 1",
    "defense": NICKEL,
    "spots": [
        spot("Q", 180, 345, [{"x": 165, "y": 395}]),
        spot("C", 175, LOS, [{"x": 175, "y": 285}, {"x": 70, "y": 285}]),
        spot("A", 95, LOS, [{"x": 95, "y": 230}, {"x": 95, "y": 190}, {"x": 45, "y": 145}]),
        spot("Y", 225, LOS, [{"x": 95, "y": 130}]),
        spot("B", 255, 315, [{"x": 255, "y": 265}, {"x": 120, "y": 250}]),
        spot("X", 285, LOS, [{"x": 285, "y": 255}, {"x": 285, "y": 235}, {"x": 255, "y": 215}]),
        spot("Z", 320, LOS, [{"x": 320, "y": 130}]),
    ],
}
P2 = {
    "num": "2",
    "title": "B Route out",
    "defense": COVER3,
    "spots": [
        # Q rolls forward-right to open circle near Y stem (not a drop below LOS)
        spot("Q", 180, 345, [{"x": 265, "y": 255}]),
        spot("C", 180, LOS, []),
        spot("X", 48, 308, [{"x": 48, "y": 290}, {"x": 38, "y": 295}, {"x": 55, "y": 285}, {"x": 48, "y": 280}, {"x": 140, "y": 280}]),
        spot("A", 110, LOS, [{"x": 110, "y": 220}, {"x": 175, "y": 220}]),
        spot("B", 215, LOS, [{"x": 215, "y": 245}, {"x": 300, "y": 245}]),
        spot("Y", 260, LOS, [{"x": 260, "y": 200}, {"x": 200, "y": 145}]),
        spot("Z", 320, LOS, [{"x": 320, "y": 120}]),
    ],
}
P19 = {
    "num": "19",
    "title": "B Route out flipped",
    "defense": [{**d, "x": flipx(d["x"])} for d in COVER3],
    "spots": [
        spot("Q", 180, 345, [{"x": 95, "y": 255}]),
        spot("C", 180, LOS, [{"x": 180, "y": 230}, {"x": 180, "y": 210}, {"x": 130, "y": 210}]),
        spot("Z", 40, LOS, [{"x": 40, "y": 120}]),
        spot("Y", 100, LOS, [{"x": 100, "y": 220}, {"x": 165, "y": 150}]),
        spot("B", 145, 320, [{"x": 145, "y": 260}, {"x": 55, "y": 260}]),
        spot("A", 250, LOS, [{"x": 250, "y": 160}]),
        spot("X", 312, 308, [{"x": 312, "y": 290}, {"x": 322, "y": 295}, {"x": 305, "y": 285}, {"x": 312, "y": 280}, {"x": 220, "y": 280}]),
    ],
}
P6 = {
    "num": "6",
    "title": "Goal Line 2",
    "endzone": True,
    "defense": NICKEL,
    "spots": [
        spot("Q", 180, 345, [{"x": 320, "y": 210}]),
        spot("C", 175, LOS, [{"x": 175, "y": 285}, {"x": 175, "y": 270}, {"x": 230, "y": 270}]),
        spot("X", 75, LOS, [{"x": 120, "y": 230}, {"x": 145, "y": 255}]),
        spot("A", 120, LOS, [{"x": 45, "y": 230}]),
        spot("B", 220, LOS, [{"x": 220, "y": 180}, {"x": 220, "y": 155}, {"x": 165, "y": 155}]),
        spot("Y", 255, LOS, [{"x": 255, "y": 270}, {"x": 270, "y": 240}, {"x": 310, "y": 160}]),
        spot("Z", 300, LOS, [{"x": 345, "y": 300}]),
    ],
}

PLAYS = {
    "23": P23,
    "26": P26,
    "38": P38,
    "68": P68,
    "2": P2,
    "19": P19,
    "6": P6,
}


def font(size):
    for name in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def arrowhead(draw, x0, y0, x1, y1, color, size=10):
    ang = math.atan2(y1 - y0, x1 - x0)
    left = (x1 - size * math.cos(ang - 0.45), y1 - size * math.sin(ang - 0.45))
    right = (x1 - size * math.cos(ang + 0.45), y1 - size * math.sin(ang + 0.45))
    draw.polygon([ (x1, y1), left, right ], fill=color)


def draw_card(play: dict) -> Image.Image:
    img = Image.new("RGB", (CW, CH), (43, 43, 43))
    draw = ImageDraw.Draw(img)
    hdr = 48 * SCALE
    # header
    draw.rectangle([0, 0, CW, hdr], fill=(180, 180, 180))
    draw.rectangle([0, 0, 56 * SCALE, hdr], fill=(28, 32, 38))
    f_num = font(22 * SCALE // 2 + 4)
    f_title = font(18 * SCALE // 2 + 2)
    draw.text((28 * SCALE, hdr // 2), play["num"], fill="white", font=f_num, anchor="mm")
    draw.text((68 * SCALE, hdr // 2), play["title"], fill=(40, 40, 40), font=f_title, anchor="lm")

    # field
    ox, oy = 0, hdr
    draw.rectangle([ox, oy, ox + FW * SCALE, oy + FH * SCALE], fill="white")
    # yard lines
    for y in range(40, FH, 20):
        yy = oy + y * SCALE
        col = (140, 140, 140) if abs(y - LOS) < 1 else (220, 220, 220)
        w = 3 if abs(y - LOS) < 1 else 1
        draw.line([(ox + 12 * SCALE, yy), (ox + (FW - 12) * SCALE, yy)], fill=col, width=w)

    if play.get("endzone"):
        draw.rectangle(
            [ox + 16 * SCALE, oy + 16 * SCALE, ox + (FW - 16) * SCALE, oy + 70 * SCALE],
            outline=(170, 170, 170),
            width=2,
        )
        draw.text((ox + 300 * SCALE, oy + 34 * SCALE), "end zone", fill=(120, 120, 120), font=font(12), anchor="mm")

    # defense
    for d in play["defense"]:
        x, y = ox + d["x"] * SCALE, oy + d["y"] * SCALE
        draw.polygon([(x, y - 10 * SCALE // 1), (x + 9 * SCALE // 1, y + 8 * SCALE // 1), (x - 9 * SCALE // 1, y + 8 * SCALE // 1)], fill=DEF_FILL)
        draw.text((x, y + 2), d["id"], fill="white", font=font(9), anchor="mm")

    # routes
    for s in play["spots"]:
        if not s["route"]:
            continue
        color = COLORS[s["letter"]]
        pts = [(ox + s["x"] * SCALE, oy + s["y"] * SCALE)] + [
            (ox + p["x"] * SCALE, oy + p["y"] * SCALE) for p in s["route"]
        ]
        draw.line(pts, fill=color, width=max(3, 3 * SCALE // 2))
        # open circle at end for Q / B / Y style finishes on some cards
        ex, ey = pts[-1]
        if s["letter"] in ("Q", "B", "Y") or (s["letter"] == "X" and play["num"] in ("2", "19")):
            r = 5 * SCALE // 1
            draw.ellipse([ex - r, ey - r, ex + r, ey + r], outline=color, width=max(2, SCALE))
        else:
            if len(pts) >= 2:
                arrowhead(draw, pts[-2][0], pts[-2][1], ex, ey, color, size=8 * SCALE // 1)

    # players
    for s in play["spots"]:
        x, y = ox + s["x"] * SCALE, oy + s["y"] * SCALE
        color = COLORS[s["letter"]]
        if s["letter"] == "C":
            half = 12 * SCALE // 1
            draw.rectangle([x - half, y - half, x + half, y + half], fill=color, outline=(20, 20, 20), width=2)
        else:
            r = 14 * SCALE // 1 if s["letter"] == "Q" else 13 * SCALE // 1
            draw.ellipse([x - r, y - r, x + r, y + r], fill=color, outline=(20, 20, 20), width=2)
        draw.text((x, y + 1), s["letter"], fill="white", font=font(13), anchor="mm")

    return img


def dump_js_spots(play):
    lines = []
    for s in play["spots"]:
        route = ",".join(f"{{x:{p['x']},y:{p['y']}}}" for p in s["route"])
        lines.append(f'      spot("{s["letter"]}",{s["x"]},{s["y"]},[{route}]),')
    return "\n".join(lines)


def main():
    coords = {}
    for key, play in PLAYS.items():
        img = draw_card(play)
        path = OUT / f"{key}.png"
        img.save(path, "PNG", optimize=True)
        print("wrote", path.name, path.stat().st_size)
        coords[key] = {
            "num": play["num"],
            "title": play["title"],
            "defense": play["defense"],
            "spots": play["spots"],
            "endzone": bool(play.get("endzone")),
        }
    (OUT / "coords.json").write_text(json.dumps(coords, indent=2), encoding="utf-8")
    print("wrote coords.json")


if __name__ == "__main__":
    main()
