require "chunky_png"

src = ChunkyPNG::Image.from_file("Char1_roll_right.png")
frame_w = 16
frame_h = 16
frames = 6

dst = ChunkyPNG::Image.new(frame_w * frames, frame_h, ChunkyPNG::Color::TRANSPARENT)

frames.times do |i|
  frame = src.crop(0, i * frame_h, frame_w, frame_h)
  dst.replace!(frame, i * frame_w, 0)
end

dst.save("horizontal1.png")