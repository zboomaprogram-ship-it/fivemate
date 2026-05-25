from PIL import Image

def pad_logo(input_path, output_path, scale_factor=0.65):
    # Load the logo image
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    
    # Determine the target square canvas size (use the max dimension)
    canvas_size = max(w, h)
    
    # Create a transparent background canvas
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 0))
    
    # Calculate the new size for the centered logo
    new_w = int(w * scale_factor)
    new_h = int(h * scale_factor)
    
    # Resize the original logo using Lanczos interpolation
    resized_img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Calculate position to center the logo
    x = (canvas_size - new_w) // 2
    y = (canvas_size - new_h) // 2
    
    # Paste the resized logo onto the transparent canvas
    canvas.paste(resized_img, (x, y), resized_img)
    
    # Save the output image
    canvas.save(output_path, "PNG")
    print(f"Padded logo saved successfully to {output_path} with scale factor {scale_factor}.")

if __name__ == "__main__":
    pad_logo("assets/logo.png", "assets/logo_launcher.png", scale_factor=0.65)
