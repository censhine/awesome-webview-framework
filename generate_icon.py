from PIL import Image, ImageDraw, ImageFont
import math
import os
import json

def create_icon(size):
    """Create a modern WebView app icon with globe + W design"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background gradient - deep blue to purple
    for i in range(size):
        ratio = i / size
        r = int(30 + ratio * 40)
        g = int(60 + ratio * 20)
        b = int(180 - ratio * 40)
        draw.line([(0, i), (size, i)], fill=(r, g, b, 255))
    
    # Rounded rectangle mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = size // 5
    mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=corner_radius, fill=255)
    img.putalpha(mask)
    draw = ImageDraw.Draw(img)
    
    # Globe symbol
    center_x = size // 2
    center_y = int(size * 0.42)
    radius = int(size * 0.28)
    globe_color = (255, 255, 255, 220)
    line_width = max(2, size // 32)
    
    # Globe circle
    draw.ellipse([center_x - radius, center_y - radius, center_x + radius, center_y + radius], 
                 outline=globe_color, width=line_width)
    
    # Horizontal lines (latitude)
    for offset in [-0.5, 0, 0.5]:
        y = center_y + int(radius * offset)
        dy = y - center_y
        dx = int(math.sqrt(max(0, radius**2 - dy**2)))
        draw.line([(center_x - dx, y), (center_x + dx, y)], fill=globe_color, width=line_width)
    
    # Vertical ellipse (longitude)
    ellipse_width = radius // 2
    draw.ellipse([center_x - ellipse_width, center_y - radius, 
                  center_x + ellipse_width, center_y + radius],
                 outline=globe_color, width=line_width)
    
    # "W" letter - skip for very small icons
    if size >= 64:
        w_size = max(10, int(size * 0.2))
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", w_size)
        except:
            font = ImageFont.load_default()
        
        text = "W"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_x = center_x - text_w // 2
        text_y = center_y + radius + int(size * 0.06)
        
        draw.text((text_x + 1, text_y + 1), text, fill=(0, 0, 0, 80), font=font)
        draw.text((text_x, text_y), text, fill=(255, 255, 255, 240), font=font)
    
    return img

# Output directory
output_dir = "WebViewApp/WebViewApp/Assets.xcassets/AppIcon.appiconset"
os.makedirs(output_dir, exist_ok=True)

# Generate all sizes
icon_1024 = create_icon(1024)
icon_1024.save(os.path.join(output_dir, "AppIcon-1024.png"))

sizes_map = {
    "16": 16, "16@2x": 32, "32": 32, "32@2x": 64,
    "128": 128, "128@2x": 256, "256": 256, "256@2x": 512,
    "512": 512, "512@2x": 1024,
}

for name, sz in sizes_map.items():
    icon = create_icon(sz)
    icon.save(os.path.join(output_dir, f"AppIcon-{name}.png"))

print("All icons generated!")

# Update Contents.json
contents = {
    "images": [
        {"idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "AppIcon-1024.png"},
        {"idiom": "universal", "platform": "macos", "size": "16x16", "scale": "1x", "filename": "AppIcon-16.png"},
        {"idiom": "universal", "platform": "macos", "size": "16x16", "scale": "2x", "filename": "AppIcon-16@2x.png"},
        {"idiom": "universal", "platform": "macos", "size": "32x32", "scale": "1x", "filename": "AppIcon-32.png"},
        {"idiom": "universal", "platform": "macos", "size": "32x32", "scale": "2x", "filename": "AppIcon-32@2x.png"},
        {"idiom": "universal", "platform": "macos", "size": "128x128", "scale": "1x", "filename": "AppIcon-128.png"},
        {"idiom": "universal", "platform": "macos", "size": "128x128", "scale": "2x", "filename": "AppIcon-128@2x.png"},
        {"idiom": "universal", "platform": "macos", "size": "256x256", "scale": "1x", "filename": "AppIcon-256.png"},
        {"idiom": "universal", "platform": "macos", "size": "256x256", "scale": "2x", "filename": "AppIcon-256@2x.png"},
        {"idiom": "universal", "platform": "macos", "size": "512x512", "scale": "1x", "filename": "AppIcon-512.png"},
        {"idiom": "universal", "platform": "macos", "size": "512x512", "scale": "2x", "filename": "AppIcon-512@2x.png"}
    ],
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join(output_dir, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print("Contents.json updated!")
for f in sorted(os.listdir(output_dir)):
    print(f"  {f}")
