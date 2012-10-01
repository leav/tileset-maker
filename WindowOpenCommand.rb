#==============================================================================
# ■ Window_OpenCommand
#------------------------------------------------------------------------------
# 　地图图块合成器的命令选择行窗口。
#==============================================================================

class Window_OpenCommand < Window_Base
  attr_reader :index
  @@top_item = 0
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     width    : 窗口的宽
  #     commands : 命令字符串序列
  #--------------------------------------------------------------------------
  def initialize(commands)
    super(0, 80, 640, 400)
    self.opacity = 160
    self.z = 200
    @item_max = commands.size
    @commands = commands
    self.contents = Bitmap.new(width - 32, height - 32)
    @index = -1
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    for i in @@top_item...[@@top_item + 10, @item_max].min
      draw_item(i, normal_color)
    end
    rect = Rect.new(368, 0, 256, 384)
    src_rect = Rect.new(0, 0, 256, 384)
    if @index >= 0
      self.contents.fill_rect(rect, VIEW_BACK_COLOR)
      self.contents.blt(368, 0, Tileset_Maker.bitmap(@commands[@index].tileset_name), src_rect)
    end
    if @@top_item <= 0
      self.contents.font.color = disabled_color
    else
      self.contents.font.color = normal_color
    end
    self.contents.draw_text(0, 336, 352, 32, '上页', 0)
    if @@top_item + 10 >= @item_max
      self.contents.font.color = disabled_color
    else
      self.contents.font.color = normal_color
    end
    self.contents.draw_text(0, 336, 352, 32, '下页', 2)
    self.contents.font.color = normal_color
    self.contents.draw_text(0, 336, 352, 32, '确定', 1)
  end
  #--------------------------------------------------------------------------
  # ● 描绘项目
  #     index : 项目编号
  #     color : 文字色
  #--------------------------------------------------------------------------
  def draw_item(index, color)
    self.contents.font.color = color
    rect = Rect.new(4, 32 * (index - @@top_item), 352, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    self.contents.draw_text(rect, '[' + @commands[index].id.to_s + ']' + @commands[index].name)
  end
  #--------------------------------------------------------------------------
  # ● 项目无效化
  #     index : 项目编号
  #--------------------------------------------------------------------------
  def disable_item(index)
    draw_item(index, disabled_color)
  end
  #--------------------------------------------------------------------------
  # ● 返回选中项目
  #--------------------------------------------------------------------------
  def item
    if @index >= 0
      return @commands[@index]
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 更新光标矩形
  #--------------------------------------------------------------------------
  def update_cursor_rect
    # 光标位置不满 0 的情况下
    if @index < 0
      self.cursor_rect.empty
      return
    end
    # 获取当前的行
    row = @index - @@top_item
    # 计算光标的宽
    cursor_width = 352
    # 计算光标坐标
    x = 0
    y = row * 32
    # 更新国标矩形
    self.cursor_rect.set(x, y, cursor_width, 32)
  end
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    super
    if self.active
      # C 键被按下的情况下
      if Input.trigger?(Input::C)
        mouse_x, mouse_y = Mouse.get_mouse_pos
        mouse_x -= self.x + 16
        mouse_y -= self.y + 16
        case mouse_y
        when 336..368
          case mouse_x
          # 上页
          when 0..64
            if @@top_item >= 10
              @@top_item = [@@top_item - 10, 0].max
              @index = -1
              refresh
              # 演奏光标SE
              $game_system.se_play($data_system.cursor_se)
            end
          # 下页
          when 288..352
            if @@top_item + 10 < @item_max
              @@top_item += 10
              @index = -1
              refresh
              # 演奏光标SE
              $game_system.se_play($data_system.cursor_se)
            end
          end
        else
          if mouse_x > 0 and mouse_x < 352 and mouse_y > 0 and mouse_y < 320
            if mouse_y / 32 < @item_max - @@top_item
              @index = mouse_y / 32 + @@top_item
              # 演奏光标SE
              $game_system.se_play($data_system.cursor_se)
              refresh
            end
          end
        end
      end
      update_cursor_rect
    end
  end
end
