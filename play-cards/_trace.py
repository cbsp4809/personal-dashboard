#!/usr/bin/env python3
"""Write Kevin-style SVG cards from the same traces as plays.html."""
from pathlib import Path

LOS = 318
FW, FH = 360, 500
COLORS = {
    "Q": "#D7263D", "C": "#3D3D3D", "X": "#F08C00", "A": "#1B6CA8",
    "B": "#6C757D", "Y": "#6F42C1", "Z": "#12B886",
}

def flipx(x):
    return FW - x

def flipp(p):
    return {"x": flipx(p["x"]), "y": p["y"]}

def flips(s):
    return {**s, "x": flipx(s["x"]), "route": [flipp(p) for p in s.get("route", [])]}

def spot(letter, x, y, route=None, star=False):
    return {"letter": letter, "x": x, "y": y, "route": route or [], "star": star}

COVER3 = [
    {"id": "C", "x": 38, "y": 276}, {"id": "C", "x": 322, "y": 276},
    {"id": "LB", "x": 138, "y": 292}, {"id": "LB", "x": 222, "y": 292},
    {"id": "SS", "x": 78, "y": 148}, {"id": "S", "x": 180, "y": 128}, {"id": "FS", "x": 282, "y": 148},
]
NICKEL = [
    {"id": "C", "x": 36, "y": 268}, {"id": "C", "x": 336, "y": 268},
    {"id": "LB", "x": 110, "y": 288}, {"id": "LB", "x": 180, "y": 288}, {"id": "LB", "x": 250, "y": 288},
    {"id": "SS", "x": 80, "y": 198}, {"id": "FS", "x": 180, "y": 148},
]

P26 = {
    "num": "26", "title": "Post Corner Right",
    "defense": COVER3,
    "spots": [
        spot("Q", 180, 356, [{"x": 292, "y": 268}]),
        spot("C", 180, LOS),
        spot("X", 68, 326, [{"x": 22, "y": 272}]),
        spot("A", 112, 324, [{"x": 112, "y": 258}, {"x": 186, "y": 258}]),
        spot("B", 214, 338, [{"x": 214, "y": 300}, {"x": 150, "y": 300}, {"x": 308, "y": 300}]),
        spot("Y", 250, 324, [{"x": 250, "y": 258}, {"x": 328, "y": 186}]),
        spot("Z", 320, 326, [{"x": 196, "y": 206}]),
    ],
}
P23 = {
    "num": "23", "title": "Post Corner Right flipped",
    "defense": [{**d, "x": flipx(d["x"])} for d in COVER3],
    "spots": [flips(s) for s in P26["spots"]],
}
P38 = {
    "num": "38", "title": "Overload first down",
    "defense": NICKEL,
    "spots": [
        spot("Q", 180, 356, star=True),
        spot("C", 180, LOS, [{"x": 180, "y": 298}, {"x": 228, "y": 298}]),
        spot("A", 118, LOS, [{"x": 118, "y": 278}, {"x": 128, "y": 268}, {"x": 48, "y": 178}]),
        spot("X", 214, LOS, [{"x": 214, "y": 258}, {"x": 286, "y": 198}]),
        spot("B", 250, LOS, [{"x": 250, "y": 278}, {"x": 292, "y": 258}, {"x": 258, "y": 248}]),
        spot("Y", 286, LOS, [{"x": 286, "y": 298}, {"x": 318, "y": 278}, {"x": 348, "y": 278}]),
        spot("Z", 328, LOS, [{"x": 248, "y": 268}, {"x": 258, "y": 218}, {"x": 330, "y": 158}]),
    ],
}
P68 = {
    "num": "68", "title": "Rice Touchdown play 1",
    "defense": NICKEL,
    "spots": [
        spot("Q", 180, 356, [{"x": 180, "y": 396}, {"x": 158, "y": 404}]),
        spot("C", 180, LOS, [{"x": 180, "y": 306}, {"x": 70, "y": 306}]),
        spot("A", 88, LOS, [{"x": 88, "y": 258}, {"x": 36, "y": 178}]),
        spot("X", 292, LOS, [{"x": 292, "y": 278}, {"x": 200, "y": 278}]),
        spot("B", 252, 330, [{"x": 252, "y": 288}, {"x": 90, "y": 278}]),
        spot("Y", 218, LOS, [{"x": 90, "y": 158}]),
        spot("Z", 330, LOS, [{"x": 330, "y": 158}]),
    ],
}
P2 = {
    "num": "2", "title": "B Route out",
    "defense": COVER3,
    "spots": [
        spot("Q", 180, 356, [{"x": 236, "y": 456}]),
        spot("C", 180, LOS),
        spot("X", 46, 326, [{"x": 46, "y": 306}, {"x": 36, "y": 312}, {"x": 52, "y": 300}, {"x": 46, "y": 298}, {"x": 160, "y": 298}]),
        spot("A", 110, LOS, [{"x": 110, "y": 218}, {"x": 180, "y": 218}]),
        spot("B", 216, LOS, [{"x": 216, "y": 238}, {"x": 316, "y": 238}]),
        spot("Y", 258, LOS, [{"x": 258, "y": 158}, {"x": 198, "y": 108}]),
        spot("Z", 322, LOS, [{"x": 322, "y": 118}]),
    ],
}
P19 = {
    "num": "19", "title": "B Route out flipped",
    "defense": [{**d, "x": flipx(d["x"])} for d in COVER3],
    "spots": [
        spot("Q", 180, 356, [{"x": 124, "y": 456}]),
        spot("C", 180, LOS, [{"x": 180, "y": 218}, {"x": 80, "y": 218}]),
        spot("Z", 38, LOS, [{"x": 38, "y": 118}]),
        spot("Y", 102, LOS, [{"x": 102, "y": 238}, {"x": 180, "y": 158}]),
        spot("B", 146, 338, [{"x": 146, "y": 278}, {"x": 46, "y": 278}]),
        spot("A", 250, LOS, [{"x": 250, "y": 158}, {"x": 242, "y": 152}]),
        spot("X", 314, 326, [{"x": 314, "y": 306}, {"x": 324, "y": 312}, {"x": 308, "y": 300}, {"x": 314, "y": 298}, {"x": 200, "y": 298}]),
    ],
}
P6 = {
    "num": "6", "title": "Goal Line 2",
    "endzone": True,
    "defense": NICKEL,
    "spots": [
        spot("Q", 180, 356, [{"x": 320, "y": 220}]),
        spot("C", 180, LOS, [{"x": 180, "y": 308}, {"x": 172, "y": 300}, {"x": 180, "y": 290}, {"x": 280, "y": 290}]),
        spot("X", 70, LOS, [{"x": 130, "y": 238}, {"x": 190, "y": 278}]),
        spot("A", 120, LOS, [{"x": 50, "y": 238}]),
        spot("B", 220, LOS, [{"x": 220, "y": 118}, {"x": 160, "y": 118}]),
        spot("Y", 258, LOS, [{"x": 278, "y": 288}, {"x": 268, "y": 268}, {"x": 288, "y": 238}, {"x": 330, "y": 138}]),
        spot("Z", 310, LOS, [{"x": 348, "y": 318}]),
    ],
}

def path_d(s):
    d = f"M{s['x']} {s['y']}"
    for p in s["route"]:
        d += f" L{p['x']} {p['y']}"
    return d

def star(x, y, r=13):
    import math
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rad = r * 0.42 if i % 2 else r
        pts.append(f"{x + math.cos(a) * rad},{y + math.sin(a) * rad}")
    return " ".join(pts)

def yards():
    lines = []
    for y in range(40, 480, 20):
        if abs(y - LOS) < 1:
            continue
        lines.append(f"M12 {y}H348")
    return (
        f'<path d="{"".join(lines)}" fill="none" stroke="#D9D9D9" stroke-width="1"/>'
        f'<path d="M12 {LOS}H348" fill="none" stroke="#8A8A8A" stroke-width="2.4"/>'
    )

def render(play):
    parts = [yards()]
    if play.get("endzone"):
        parts.append('<rect x="16" y="16" width="328" height="56" fill="none" stroke="#B0B0B0" stroke-width="2"/>')
        parts.append('<text x="300" y="34" fill="#777" font-size="9">end zone</text>')
    for d in play["defense"]:
        parts.append(
            f'<polygon points="{d["x"]},{d["y"]-9} {d["x"]+8},{d["y"]+7} {d["x"]-8},{d["y"]+7}" fill="#4A4A4A"/>'
            f'<text x="{d["x"]}" y="{d["y"]+3}" fill="#fff" text-anchor="middle" font-size="7">{d["id"]}</text>'
        )
    for s in play["spots"]:
        if s["route"]:
            parts.append(
                f'<path d="{path_d(s)}" fill="none" stroke="{COLORS[s["letter"]]}" '
                f'stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>'
            )
    for s in play["spots"]:
        fill = COLORS[s["letter"]]
        if s.get("star"):
            parts.append(f'<polygon points="{star(s["x"], s["y"])}" fill="{fill}" stroke="#1C1C1C" stroke-width="1.6"/>')
        elif s["letter"] == "C":
            parts.append(
                f'<rect x="{s["x"]-11}" y="{s["y"]-11}" width="22" height="22" fill="{fill}" stroke="#1C1C1C" stroke-width="1.6"/>'
            )
        else:
            r = 13 if s["letter"] == "Q" else 12
            parts.append(
                f'<circle cx="{s["x"]}" cy="{s["y"]}" r="{r}" fill="{fill}" stroke="#1C1C1C" stroke-width="1.6"/>'
            )
        parts.append(
            f'<text x="{s["x"]}" y="{s["y"]+4}" fill="#fff" text-anchor="middle" font-size="11">{s["letter"]}</text>'
        )
    inner = "\n    ".join(parts)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 548" role="img" aria-label="{play["num"]} {play["title"]}">
  <rect width="360" height="548" fill="#2B2B2B"/>
  <rect x="10" y="10" width="44" height="28" fill="#111"/>
  <text x="32" y="30" fill="#fff" text-anchor="middle" font-size="14" font-family="Figtree,Helvetica,sans-serif" font-weight="700">{play["num"]}</text>
  <text x="64" y="30" fill="#E8E8E8" font-size="13" font-family="Figtree,Helvetica,sans-serif">{play["title"]}</text>
  <g transform="translate(0,40)">
    <rect width="{FW}" height="{FH}" fill="#fff"/>
    <rect x="8" y="8" width="344" height="484" fill="none" stroke="#C8C8C8" stroke-width="1.5"/>
    {inner}
  </g>
</svg>
'''

def main():
    out = Path(__file__).resolve().parent
    for play, name in [
        (P23, "23.svg"), (P26, "26.svg"), (P38, "38.svg"),
        (P68, "68.svg"), (P2, "2.svg"), (P19, "19.svg"), (P6, "6.svg"),
    ]:
        (out / name).write_text(render(play), encoding="utf-8")
        print("wrote", name)

if __name__ == "__main__":
    main()
