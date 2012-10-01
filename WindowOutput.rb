#==============================================================================
# ■ Window_Output
#------------------------------------------------------------------------------
# 　地图图块合成器的导出窗口。
#==============================================================================

class Window_Output < Window_Base
  attr_reader :index
  attr_reader :data
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     width    : 窗口的宽
  #     commands : 命令字符串序列
  #--------------------------------------------------------------------------
  def initialize(data)
    super(104, 80, 488, 160)
    self.opacity = 160
    self.z = 200
    @item_max = data.size
    @data = data
    @index = @item_max
    self.contents = Bitmap.new(width - 32, height - 32)
    self.contents.draw_text(0, 0, 352, 32, '请选择导出图块数据库ID：')
    src_rect = Rect.new(0, 0, 24, 24)
    up_icon = RPG::Cache.icon('048-Skill05')
    down_icon = RPG::Cache.icon('047-Skill04')
    self.contents.blt(368, 38, up_icon, src_rect)
    self.contents.blt(368, 66, down_icon, src_rect)
    self.contents.draw_text(392, 48, 64, 32, '确定', 1)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.contents.fill_rect(0, 48, 352, 32, Color.new(0,0,0,0))
    self.contents.fill_rect(0, 96, 472, 32, Color.new(0,0,0,0))
    if @data[@index] != nil
      tileset_id = @data[@index].id
      tileset_name = @data[@index].name
      self.contents.draw_text(0, 96, 456, 32, '警告:当前ID已存在，导出时将会覆盖其中数据')
    else
      tileset_id = @index
      tileset_name = '[空白]'
    end
    self.contents.draw_text(0, 48, 352, 32, '[' + tileset_id.to_s + ']' + tileset_name)
  end
  #--------------------------------------------------------------------------
  # ● 描绘文字
  #--------------------------------------------------------------------------
  def draw_text(text)
    self.contents.clear
    self.contents.draw_text(0, 0, width - 32, height - 32, text)
  end
  #--------------------------------------------------------------------------
  # ● 当前命令
  #--------------------------------------------------------------------------
  def command(mouse_x, mouse_y)
    if mouse_x >= 392 and mouse_x < 456 and mouse_y > 48 and mouse_y < 80
      return '确定'
    end
    return nil
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
        case mouse_x
        when 368...392
          case mouse_y
          # 上翻
          when 38...62
            if @index > 1
              @index -= 1
              refresh
              # 演奏光标SE
              $game_system.se_play($data_system.cursor_se)
            end
          # 下翻
          when 66...90
            @index += 1
            refresh
            # 演奏光标SE
            $game_system.se_play($data_system.cursor_se)
          end
        end
      end
    end
  end
end
