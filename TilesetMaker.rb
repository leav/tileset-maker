module Tileset_Maker
  def self.bitmap(file_name)
    begin
      bitmap = RPG::Cache.tileset(file_name)
    rescue
      begin
        path = PATH + "/Graphics/Tilesets/" + file_name
        bitmap = Bitmap.new(path)
      rescue
        bitmap = Bitmap.new(256, 96)
        bitmap.font.color = Color.new(0, 0, 0)
        bitmap.draw_text(0, 32, 256, 32, '找不到图片', 1)
      end
    end
    return bitmap
  end
end