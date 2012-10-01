#==============================================================================
# ■ Window_CopyType
#------------------------------------------------------------------------------
# 　地图图块合成器的粘贴选择窗口。
#==============================================================================

class Window_CopyType < Window_Base
  attr_reader :index
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     width    : 窗口的宽
  #     commands : 命令字符串序列
  #--------------------------------------------------------------------------
  def initialize(x, y, width, commands)
    super(x, y, width, commands.size * 32 + 80)
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
    for i in 0...@item_max
      draw_item(i, normal_color)
    end
    self.contents.font.color = normal_color
    rect = Rect.new((self.width - 32) / 2 - 32, @item_max * 32 + 16, 64, 32)
    self.contents.draw_text(rect, '确定', 1)
  end
  #--------------------------------------------------------------------------
  # ● 描绘项目
  #     index : 项目编号
  #     color : 文字色
  #--------------------------------------------------------------------------
  def draw_item(index, color)
    self.contents.font.color = color
    rect = Rect.new(4, 32 * index, self.width - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    self.contents.draw_text(rect, @commands[index])
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
  # ● 返回选中命令
  #--------------------------------------------------------------------------
  def command(mouse_x, mouse_y)
    if mouse_x > (self.width - 32) / 2 - 32 and mouse_x < (self.width - 32) / 2 + 32
      if mouse_y > @item_max * 32 + 16 and mouse_y < @item_max * 32 + 48
        return '确定'
      end
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
    row = @index
    # 计算光标的宽
    cursor_width = self.width - 32
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
        if mouse_x > 0 and mouse_x < self.width - 16 and
          mouse_y > 0 and mouse_y < self.height - 16
          if mouse_y / 32 < @item_max
            @index = mouse_y / 32
            # 演奏光标SE
            $game_system.se_play($data_system.cursor_se)
            refresh
          end
        end
      end
      update_cursor_rect
    end
  end
end
