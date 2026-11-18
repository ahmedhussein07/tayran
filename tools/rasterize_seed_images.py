"""
One-off: rasterize the design export's category illustrations and product art into PNG sources
for the dev seed (backend/seed-images/). The dev seeder then runs these PNGs through the REAL
image pipeline, so no image URL is ever hardcoded.

Usage (from the repo root):
    python tools/rasterize_seed_images.py "E:/local/app/Tayran-design-export" backend/seed-images

Needs Google Chrome (headless) for SVG rendering with a transparent background.
"""
import os
import pathlib
import subprocess
import sys
import tempfile

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]

SIZE = 640

# Name in seed-images -> file in the export's _blob folder (names from the export's own pages).
ART = {
    # Category illustrations
    "produce": "a804ffa99451ac78e4ca58b62e000738.svg",
    "bread": "6d61b2d168876d23a7e810764bd9df82.svg",
    "dairy": "b4f5481e4d4314a9e46d3c0d9628fc45.svg",
    "chicken": "5b6790052d0d000855a016c84488a696.svg",
    "chips": "9dd3bf42e0631d2083976cf3883be8cb.svg",
    "juice": "39b360191afdc62360a397b7ffa12cf5.svg",
    "spray": "c858a900ebcb2e2d4872daa3441dba76.svg",
    "pump": "918e5b42ec043c930ad360352822bf48.svg",
    # Sample product illustrations
    "tomato": "a02a39efccc01f588c78009456d94b04.svg",
    "banana": "b1a4479ee22541f02287597b264a3de2.svg",
    "cucumber": "26cf04d3451d62efe56180471f6a9adf.svg",
    "carrot": "6c3e9f73705b3f74c522701c4930c518.svg",
    "milk": "b8ac1523d314b6a0b0aa37f2bce777c9.svg",
    "eggs": "0f501aca37096e7c211f55d9779904df.svg",
    "cheese": "aa528d0c0abd1710dc0da8421c3e0df4.svg",
    "bag": "b3341f39be97999413b1e9e45791b329.svg",
    # Packshots (invented labels, no real brands)
    "milk-full": "1e2438c907fc24c7c9ebe15ea1c6ef20.svg",
    "milk-skim": "e6c7544c3feb98b62d47ce54d19959d2.svg",
    "choco-milk": "3617f6cc61954af916f2c43111054d69.svg",
    "yogurt-plain": "601ff57aa4d6c2bd13c1afe8a1aea6fd.svg",
    "yogurt-strawberry": "7569ece756b32515a6a374e45306476a.svg",
    "yogurt-greek": "8c7b262983a652b90554cd5113400945.svg",
    "rayeb": "0f17faf688391da2085ce129bad84bde.svg",
    "white-cheese": "e950a9e0215371f2813af40bf288d0cb.svg",
    "romy": "67c80f204663e2e63cac5428e39fa344.svg",
    "cheddar": "941065bac3021b564ae6d7d14fad4ef3.svg",
    "labneh": "e7676253179db296c5d95245c59a66db.svg",
    "eggs-red": "739ba3d330598d28650e3802d6c4bfce.svg",
    "eggs-white": "090c377479c713cb5d7335215884a361.svg",
    "butter": "ec5de4ba86b54e72a0763b5d2f3c7f7c.svg",
    "cream": "b7d2e5d0cd5968d4e243cc17d595e851.svg",
}


def chrome() -> str:
    for path in CHROME_CANDIDATES:
        if os.path.exists(path):
            return path
    sys.exit("Chrome or Edge not found")


def main() -> None:
    export = pathlib.Path(sys.argv[1]).resolve()
    out = pathlib.Path(sys.argv[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    browser = chrome()
    with tempfile.TemporaryDirectory() as tmp:
        for name, blob in ART.items():
            svg = (export / "_blob" / blob).as_uri()
            page = pathlib.Path(tmp) / f"{name}.html"
            page.write_text(
                "<!doctype html><html><head><style>html,body{margin:0;background:transparent}"
                f"img{{display:block;width:{SIZE}px;height:{SIZE}px}}</style></head>"
                f'<body><img src="{svg}"></body></html>',
                encoding="utf-8",
            )
            target = out / f"{name}.png"
            subprocess.run(
                [browser, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                 "--default-background-color=00000000", "--force-device-scale-factor=1",
                 f"--window-size={SIZE},{SIZE}", "--virtual-time-budget=2000",
                 f"--screenshot={target}", page.as_uri()],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            print(f"{name}.png  {target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
