require "chunky_png"

# Folder containing your slime PNGs
INPUT_DIR  = "./"
OUTPUT_DIR = "./converted/"

Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

Dir.glob(File.join(INPUT_DIR, "slime_*.png")).each do |file|
  puts "Processing #{file}..."

  src = ChunkyPNG::Image.from_file(file)

  frame_w = 16
  frame_h = 16

  # Automatically detect number of frames based on height
  frames = src.height / frame_h

  # Create destination image (horizontal layout)
  dst = ChunkyPNG::Image.new(frame_w * frames, frame_h, ChunkyPNG::Color::TRANSPARENT)

  frames.times do |i|
    frame = src.crop(0, i * frame_h, frame_w, frame_h)
    dst.replace!(frame, i * frame_w, 0)
  end

  # Output filename
  base = File.basename(file, ".png")
  out_file = File.join(OUTPUT_DIR, "#{base}h.png")

  dst.save(out_file)
  puts "Saved → #{out_file}"
end

puts "Done!"
