import os
from PIL import Image, ImageDraw, ImageFilter

def frame_highres_screenshot(im):
    sw, sh = im.size
    
    target_sw = 400
    target_sh = int(target_sw * (sh / sw))
    
    screen = im.resize((target_sw, target_sh), Image.Resampling.LANCZOS).convert("RGBA")
    
    canvas_w = 460
    canvas_h = target_sh + 60
    
    dev_left = 18
    dev_top = 18
    dev_w = 424
    dev_h = target_sh + 24
    dev_radius = 48
    
    screen_left = dev_left + 12
    screen_top = dev_top + 12
    screen_radius = 40
    
    scale = 4
    SW = canvas_w * scale
    SH = canvas_h * scale
    
    canvas = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    
    shadow_mask = Image.new("L", (SW, SH), 0)
    shadow_draw = ImageDraw.Draw(shadow_mask)
    shadow_box = [
        (dev_left + 4) * scale,
        (dev_top + 10) * scale,
        (dev_left + dev_w - 4) * scale,
        (dev_top + dev_h + 10) * scale
    ]
    shadow_draw.rounded_rectangle(shadow_box, radius=dev_radius * scale, fill=180)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(radius=12 * scale))
    
    shadow_img = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
    shadow_img.paste((0, 0, 0, 60), (0, 0), shadow_mask)
    canvas = Image.alpha_composite(canvas, shadow_img)
    
    draw = ImageDraw.Draw(canvas)
    
    draw.rounded_rectangle([
        (dev_left - 4) * scale, (dev_top + 110) * scale,
        (dev_left + 2) * scale, (dev_top + 145) * scale
    ], radius=2*scale, fill=(35, 35, 38, 255))
    draw.rounded_rectangle([
        (dev_left - 4) * scale, (dev_top + 165) * scale,
        (dev_left + 2) * scale, (dev_top + 215) * scale
    ], radius=2*scale, fill=(35, 35, 38, 255))
    draw.rounded_rectangle([
        (dev_left - 4) * scale, (dev_top + 230) * scale,
        (dev_left + 2) * scale, (dev_top + 280) * scale
    ], radius=2*scale, fill=(35, 35, 38, 255))
    draw.rounded_rectangle([
        (dev_left + dev_w - 2) * scale, (dev_top + 180) * scale,
        (dev_left + dev_w + 4) * scale, (dev_top + 260) * scale
    ], radius=2*scale, fill=(35, 35, 38, 255))
    
    dev_box = [
        dev_left * scale, dev_top * scale,
        (dev_left + dev_w) * scale, (dev_top + dev_h) * scale
    ]
    draw.rounded_rectangle(dev_box, radius=dev_radius * scale, fill=(28, 28, 30, 255), outline=(75, 75, 80, 255), width=2*scale)
    
    bezel_box = [
        (dev_left + 8) * scale, (dev_top + 8) * scale,
        (dev_left + dev_w - 8) * scale, (dev_top + dev_h - 8) * scale
    ]
    draw.rounded_rectangle(bezel_box, radius=(dev_radius - 6) * scale, fill=(5, 5, 5, 255))
    
    screen_w_scaled = target_sw * scale
    screen_h_scaled = target_sh * scale
    screen_scaled = screen.resize((screen_w_scaled, screen_h_scaled), Image.Resampling.LANCZOS)
    
    screen_mask = Image.new("L", (screen_w_scaled, screen_h_scaled), 0)
    mask_draw = ImageDraw.Draw(screen_mask)
    mask_draw.rounded_rectangle([0, 0, screen_w_scaled, screen_h_scaled], radius=screen_radius * scale, fill=255)
    
    screen_cropped = Image.new("RGBA", (screen_w_scaled, screen_h_scaled), (0, 0, 0, 0))
    screen_cropped.paste(screen_scaled, (0, 0), screen_mask)
    
    canvas.paste(screen_cropped, (screen_left * scale, screen_top * scale), screen_cropped)
    
    di_w = 110 * scale
    di_h = 28 * scale
    di_x = (canvas_w * scale - di_w) // 2
    di_y = (screen_top + 10) * scale
    draw.rounded_rectangle([di_x, di_y, di_x + di_w, di_y + di_h], radius=14 * scale, fill=(0, 0, 0, 255))
    draw.ellipse([di_x + 16 * scale, di_y + 8 * scale, di_x + 28 * scale, di_y + 20 * scale], fill=(12, 16, 28, 255), outline=(25, 30, 45, 255), width=1*scale)
    draw.ellipse([di_x + 72 * scale, di_y + 9 * scale, di_x + 84 * scale, di_y + 21 * scale], fill=(10, 10, 12, 255))

    speaker_w = 40 * scale
    speaker_h = 3 * scale
    sp_x = (canvas_w * scale - speaker_w) // 2
    sp_y = (dev_top + 6) * scale
    draw.rounded_rectangle([sp_x, sp_y, sp_x + speaker_w, sp_y + speaker_h], radius=2 * scale, fill=(35, 35, 38, 255))
    
    final_img = canvas.resize((canvas_w, canvas_h), Image.Resampling.LANCZOS)
    return final_img

mapping = {
    'real_map_view.png': 'docs/assets/map_view.png',
    'real_filter_view.png': 'docs/assets/filter_view.png',
    'real_favorites_view.png': 'docs/assets/favorites_view.png',
    'real_report_view.png': 'docs/assets/report_view.png'
}

framed_images = []
for src, dst in mapping.items():
    src_path = os.path.join('/tmp', src)
    if os.path.exists(src_path):
        im = Image.open(src_path)
        framed = frame_highres_screenshot(im)
        framed.save(dst, "PNG")
        framed_images.append(framed)
        print(f"Saved {dst} -> size: {framed.size}")

if framed_images:
    gif_path = "docs/assets/demo.gif"
    gif_frames = []
    for img in framed_images:
        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
        composed = Image.alpha_composite(bg, img).convert("RGB")
        gif_frames.append(composed)
        
    gif_frames[0].save(
        gif_path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=1500,
        loop=0
    )
    print(f"Saved {gif_path} with {len(gif_frames)} frames!")
