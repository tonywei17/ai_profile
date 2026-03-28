#!/usr/bin/env python3
"""Generate AIIDPhoto App Store screenshots for iPhone 6.9" and iPad Pro 13"."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "raw")

# Device specs
DEVICES = {
    "iphone": {"W": 1320, "H": 2868, "phone_w": 900, "phone_r": 56, "phone_y": 610,
               "title_size": 120, "sub_size": 56, "title_y": 200, "label": "iPhone-6.9"},
    "ipad":   {"W": 2048, "H": 2732, "phone_w": 1500, "phone_r": 40, "phone_y": 580,
               "title_size": 140, "sub_size": 64, "title_y": 180, "label": "iPad-13"},
}

# Warm editorial palette matching app's paperTan aesthetic
GRADIENTS = {
    "bg-1": [("#3c342a", 0.0), ("#2a2218", 0.3), ("#161210", 1.0)],   # warm brown
    "bg-2": [("#2e2838", 0.0), ("#1e1828", 0.3), ("#100e16", 1.0)],   # warm mauve
    "bg-3": [("#1f3040", 0.0), ("#142028", 0.3), ("#0c1418", 1.0)],   # warm teal
    "bg-4": [("#38301e", 0.0), ("#28200e", 0.3), ("#18140a", 1.0)],   # warm amber
}

DECO_COLORS = {
    "deco-1": "#d6c9b5",   # paperTan
    "deco-2": "#c8a8e0",   # lavender
    "deco-3": "#88ccb8",   # mint
    "deco-4": "#e8c078",   # amber
}

def get_deco_pos(deco_key, W, H):
    positions = {
        "deco-1": (W + 100, -100),
        "deco-2": (-150, H - 500),
        "deco-3": (-200, 100),
        "deco-4": (W + 50, -50),
    }
    return positions[deco_key]

ACCENT = {"accent-1": "#e8d5be", "accent-2": "#c8a8e0", "accent-3": "#88ccb8", "accent-4": "#e8c078"}
SUB    = {"sub-1": "#d0c0a8", "sub-2": "#b090c8", "sub-3": "#70b8a0", "sub-4": "#d0a860"}

FONTS = {
    "ja_title": ("Hiragino Sans", "W8"),
    "ja_sub":   ("Hiragino Sans", "W5"),
    "en_title": ("Helvetica Neue", "Bold"),
    "en_sub":   ("Helvetica Neue", "Regular"),
    "zh_title": ("PingFang SC", "Semibold"),
    "zh_sub":   ("PingFang SC", "Regular"),
    "ko_title": ("Apple SD Gothic Neo", "Bold"),
    "ko_sub":   ("Apple SD Gothic Neo", "Regular"),
}

SCREENSHOTS = {
    "ja": [
        {"img": "IMG_2279.PNG", "title": "AI証明写真",         "subtitle": "規格を選んでワンタップで生成",     "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_2280.PNG", "title": "美肌 & 服装チェンジ", "subtitle": "美肌・髪型・背景色も自由自在",     "bg": "bg-2", "accent": "accent-2", "sub": "sub-2", "deco": "deco-2"},
        {"img": "IMG_2281.PNG", "title": "ビフォー・アフター",   "subtitle": "AI変換の仕上がりを即座に確認",    "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_2282.PNG", "title": "コンビニプリント対応", "subtitle": "L判・2Lサイズに自動レイアウト",    "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "en": [
        {"img": "IMG_2279.PNG", "title": "AI ID Photos",       "subtitle": "Pick a spec, generate in one tap",     "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_2280.PNG", "title": "Beauty & Outfit",     "subtitle": "Skin, hair, background — fully custom", "bg": "bg-2", "accent": "accent-2", "sub": "sub-2", "deco": "deco-2"},
        {"img": "IMG_2281.PNG", "title": "Before & After",      "subtitle": "See the AI transformation instantly",  "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_2282.PNG", "title": "Print-Ready Layout",  "subtitle": "Auto-layout for L-size & 2L paper",   "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "zh-Hans": [
        {"img": "IMG_2279.PNG", "title": "AI 智能证件照",   "subtitle": "选好规格 一键生成",               "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_2280.PNG", "title": "美颜 & 换装",     "subtitle": "美肌、发型、背景色自由定制",       "bg": "bg-2", "accent": "accent-2", "sub": "sub-2", "deco": "deco-2"},
        {"img": "IMG_2281.PNG", "title": "前后对比",        "subtitle": "AI 生成效果一目了然",              "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_2282.PNG", "title": "排版即刻打印",    "subtitle": "L判/2L自动排版 便利店直接打印",     "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "ko": [
        {"img": "IMG_2279.PNG", "title": "AI 증명사진",      "subtitle": "규격 선택, 원탭으로 생성",           "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_2280.PNG", "title": "뷰티 & 의상 변경",  "subtitle": "피부, 헤어, 배경색 자유 커스텀",    "bg": "bg-2", "accent": "accent-2", "sub": "sub-2", "deco": "deco-2"},
        {"img": "IMG_2281.PNG", "title": "전후 비교",         "subtitle": "AI 변환 결과를 즉시 확인",          "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_2282.PNG", "title": "편의점 인쇄 대응",  "subtitle": "L판/2L 자동 레이아웃",             "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
}

IPAD_SCREENSHOTS = {
    "ja": [
        {"img": "IMG_0050.PNG", "title": "AI証明写真",         "subtitle": "規格を選んでワンタップで生成",     "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_0051.PNG", "title": "ビフォー・アフター",   "subtitle": "AI変換の仕上がりを即座に確認",    "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_0052.PNG", "title": "コンビニプリント対応", "subtitle": "L判・2Lサイズに自動レイアウト",    "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "en": [
        {"img": "IMG_0050.PNG", "title": "AI ID Photos",       "subtitle": "Pick a spec, generate in one tap",     "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_0051.PNG", "title": "Before & After",      "subtitle": "See the AI transformation instantly",  "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_0052.PNG", "title": "Print-Ready Layout",  "subtitle": "Auto-layout for L-size & 2L paper",   "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "zh-Hans": [
        {"img": "IMG_0050.PNG", "title": "AI 智能证件照",   "subtitle": "选好规格 一键生成",               "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_0051.PNG", "title": "前后对比",        "subtitle": "AI 生成效果一目了然",              "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_0052.PNG", "title": "排版即刻打印",    "subtitle": "L判/2L自动排版 便利店直接打印",     "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
    "ko": [
        {"img": "IMG_0050.PNG", "title": "AI 증명사진",      "subtitle": "규격 선택, 원탭으로 생성",           "bg": "bg-1", "accent": "accent-1", "sub": "sub-1", "deco": "deco-1"},
        {"img": "IMG_0051.PNG", "title": "전후 비교",         "subtitle": "AI 변환 결과를 즉시 확인",          "bg": "bg-3", "accent": "accent-3", "sub": "sub-3", "deco": "deco-3"},
        {"img": "IMG_0052.PNG", "title": "편의점 인쇄 대응",  "subtitle": "L판/2L 자동 레이아웃",             "bg": "bg-4", "accent": "accent-4", "sub": "sub-4", "deco": "deco-4"},
    ],
}


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient(img, stops, W, H):
    """Draw a three-stop linear gradient top→bottom."""
    draw = ImageDraw.Draw(img)
    colors = [(hex_to_rgb(c), s) for c, s in stops]
    for y in range(H):
        t = y / H
        if t <= colors[1][1]:
            ratio = t / colors[1][1] if colors[1][1] > 0 else 0
            c = lerp_color(colors[0][0], colors[1][0], ratio)
        else:
            ratio = (t - colors[1][1]) / (1 - colors[1][1])
            c = lerp_color(colors[1][0], colors[2][0], ratio)
        draw.line([(0, y), (W, y)], fill=c)


def draw_deco(img, deco_key, W, H):
    """Draw a blurred radial glow."""
    color = hex_to_rgb(DECO_COLORS[deco_key])
    cx, cy = get_deco_pos(deco_key, W, H)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    r = 300
    for i in range(r, 0, -2):
        alpha = int(40 * (i / r))
        gd.ellipse([cx - i, cy - i, cx + i, cy + i], fill=(*color, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    img.paste(Image.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, 0)), glow), (0, 0), glow)


def get_font(lang, kind, size):
    """Try to load a macOS system font."""
    # Map lang codes for font lookup
    font_lang = lang.split("-")[0]  # zh-Hans -> zh
    if font_lang not in ("ja", "en", "zh", "ko"):
        font_lang = "en"
    actual_key = f"{font_lang}_{kind}"

    name, weight = FONTS.get(actual_key, FONTS["en_title"])

    # macOS font paths
    candidates = [
        f"/System/Library/Fonts/ヒラギノ角ゴシック {weight}.ttc",
        f"/System/Library/Fonts/Hiragino Sans {weight}.ttc",
        f"/Library/Fonts/{name}.ttc",
        f"/System/Library/Fonts/{name}.ttc",
        f"/System/Library/Fonts/Supplemental/{name}.ttc",
        f"/System/Library/Fonts/Supplemental/{name} {weight}.otf",
        f"/System/Library/Fonts/Supplemental/{name}-{weight}.otf",
        f"/System/Library/Fonts/{name}.ttf",
        f"/Library/Fonts/Apple SD Gothic Neo.ttc",
        f"/System/Library/Fonts/AppleSDGothicNeo.ttc",
        f"/System/Library/Fonts/PingFang.ttc",
    ]

    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue

    # Fallback
    try:
        return ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc", size)
    except Exception:
        return ImageFont.load_default()


def round_corners(img, radius):
    """Apply rounded corners to an image."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, img.size[0], img.size[1]], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def generate_screenshot(lang, item, num, out_dir, device="iphone"):
    """Generate a single screenshot for the specified device."""
    dev = DEVICES[device]
    W, H = dev["W"], dev["H"]
    phone_w = dev["phone_w"]
    phone_r = dev["phone_r"]
    phone_y_start = dev["phone_y"]
    title_size = dev["title_size"]
    sub_size = dev["sub_size"]
    title_y_pos = dev["title_y"]
    label = dev["label"]

    # Create RGBA base
    base = Image.new("RGBA", (W, H), (0, 0, 0, 255))

    # Draw gradient background
    draw_gradient(base, GRADIENTS[item["bg"]], W, H)

    # Draw decorative glow
    draw_deco(base, item["deco"], W, H)

    draw = ImageDraw.Draw(base)

    # Title
    font_lang = lang.split("-")[0]
    title_font = get_font(font_lang, "title", title_size)
    sub_font = get_font(font_lang, "sub", sub_size)

    title_color = hex_to_rgb(ACCENT[item["accent"]])
    sub_color = hex_to_rgb(SUB[item["sub"]])

    # Title shadow
    shadow_color = (0, 0, 0)
    title_bbox = draw.textbbox((0, 0), item["title"], font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    title_x = (W - title_w) // 2
    title_y = title_y_pos

    draw.text((title_x + 2, title_y + 4), item["title"], fill=shadow_color, font=title_font)
    draw.text((title_x, title_y), item["title"], fill=title_color, font=title_font)

    # Subtitle
    sub_bbox = draw.textbbox((0, 0), item["subtitle"], font=sub_font)
    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = (W - sub_w) // 2
    sub_y = title_y + 160

    draw.text((sub_x + 1, sub_y + 2), item["subtitle"], fill=shadow_color, font=sub_font)
    draw.text((sub_x, sub_y), item["subtitle"], fill=sub_color, font=sub_font)

    # Phone/tablet screenshot
    raw_path = os.path.join(RAW_DIR, item["img"])
    phone_img = Image.open(raw_path).convert("RGBA")

    # Resize to device frame width
    phone_h = int(phone_img.height * phone_w / phone_img.width)
    phone_img = phone_img.resize((phone_w, phone_h), Image.LANCZOS)

    # Round corners
    phone_img = round_corners(phone_img, phone_r)

    # Position
    phone_x = (W - phone_w) // 2
    phone_y = phone_y_start

    # Drop shadow
    shadow = Image.new("RGBA", (phone_w + 80, phone_h + 80), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle([20, 20, phone_w + 60, phone_h + 60], radius=phone_r, fill=(0, 0, 0, 80))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=40))
    base.paste(shadow, (phone_x - 40, phone_y - 20), shadow)

    # Paste screenshot
    base.paste(phone_img, (phone_x, phone_y), phone_img)

    # Subtle white border
    border_overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_overlay)
    border_draw.rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
        radius=phone_r, outline=(255, 255, 255, 25), width=3
    )
    base = Image.alpha_composite(base, border_overlay)

    # Save
    out_path = os.path.join(out_dir, f"{label}-0{num}.png")
    base.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


def main():
    # Parse CLI: python3 generate.py [iphone|ipad|all]
    target = sys.argv[1] if len(sys.argv) > 1 else "all"

    jobs = []
    if target in ("iphone", "all"):
        for lang, items in SCREENSHOTS.items():
            for i, item in enumerate(items):
                jobs.append((lang, item, i + 1, "iphone"))
    if target in ("ipad", "all"):
        for lang, items in IPAD_SCREENSHOTS.items():
            for i, item in enumerate(items):
                jobs.append((lang, item, i + 1, "ipad"))

    total = len(jobs)
    for done, (lang, item, num, device) in enumerate(jobs, 1):
        out_dir = os.path.join(BASE_DIR, lang)
        os.makedirs(out_dir, exist_ok=True)
        print(f"[{done}/{total}] {device} {lang} #{num}: {item['title']}")
        path = generate_screenshot(lang, item, num, out_dir, device)
        print(f"  → {path}")

    print(f"\nDone! Generated {total} screenshots.")


if __name__ == "__main__":
    main()
