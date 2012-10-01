#==============================================================================
# ■ Window_Back
#------------------------------------------------------------------------------
# 　地图图块合成器的背景窗口。
#==============================================================================

class Window_Back < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     width    : 窗口的宽
  #     commands : 命令字符串序列
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, 640, 480)
    self.contents = Bitmap.new(608, 448)
    self.contents.font.color = system_color
    self.contents.draw_text(16, 32, 96, 32, '源图块')
    self.contents.draw_text(312, 32, 128, 32, '目标图块')
    self.contents.font.color = normal_color
    self.contents.draw_text(230, 32, 66, 32, '打开..')
    self.contents.draw_text(526, 32, 66, 32, '导出..')
    # 滚动条
    src_rect = Rect.new(0, 0, 24, 24)
    up_icon = RPG::Cache.icon('048-Skill05')
    down_icon = RPG::Cache.icon('047-Skill04')
    self.contents.blt(272, 64, up_icon, src_rect)
    self.contents.blt(272, 424, down_icon, src_rect)
    self.contents.blt(568, 64, up_icon, src_rect)
    self.contents.blt(568, 424, down_icon, src_rect)
    self.contents.fill_rect(272, 88, 24, 336, Color.new(68, 68, 170, 125))
    self.contents.fill_rect(568, 88, 24, 336, Color.new(68, 68, 170, 125))
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh(back = false, forward = false, paste = false, clear = false, reduce_height = false)
    @commands = []
    self.contents.fill_rect(0, 0, 608, 32, Color.new(0, 0, 0, 0))
    text_rect = Rect.new(0, 0, 32, 32)
    x = 0
    @commands.push(x)
    self.contents.font.color = back ? normal_color : disabled_color
    text_rect.set(x, 0, self.contents.text_size('撤消').width + 12, 32)
    self.contents.draw_text(text_rect, '撤消', 1)
    self.contents.font.color = forward ? normal_color : disabled_color
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('恢复').width + 12, 32)
    self.contents.draw_text(text_rect, '恢复', 1)
    self.contents.font.color = paste ? normal_color : disabled_color
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('粘贴').width + 12, 32)
    self.contents.draw_text(text_rect, '粘贴', 1)
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('特殊粘贴..').width + 12, 32)
    self.contents.draw_text(text_rect, '特殊粘贴..', 1)
    self.contents.font.color = clear ? normal_color : disabled_color
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('清除').width + 12, 32)
    self.contents.draw_text(text_rect, '清除', 1)
    self.contents.font.color = normal_color
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('增加高度').width + 12, 32)
    self.contents.draw_text(text_rect, '增加高度', 1)
    self.contents.font.color = reduce_height ? normal_color : disabled_color
    x += text_rect.width
    @commands.push(x)
    text_rect.set(x, 0, self.contents.text_size('减少高度').width + 12, 32)
    self.contents.draw_text(text_rect, '减少高度', 1)
    x += text_rect.width
    @commands.push(x)
  end
  #--------------------------------------------------------------------------
  # ● 返回(x, y)坐标的命令
  #--------------------------------------------------------------------------
  def command(x, y)
    case y
    when 0...32
      case x
      when @commands[0]...@commands[1]
        return '撤消'
      when @commands[1]...@commands[2]
        return '恢复'
      when @commands[2]...@commands[3]
        return '粘贴'
      when @commands[3]...@commands[4]
        return '特殊粘贴..'
      when @commands[4]...@commands[5]
        return '清除'
      when @commands[5]...@commands[6]
        return '增加高度'
      when @commands[6]...@commands[7]
        return '减少高度'
      end
    when 32...64
      case x
      when 230...296
        return '打开..'
      when 526...592
        return '导出..'
      end
    when 64...88
      case x
      when 272...296
        return '源上'
      when 568...592
        return '目标上'
      end
    when 88...424
      case x
      when 272...296
        return ['源', (y - 88) * 100 / 336]
      when 568...592
        return ['目标', (y - 88) * 100 / 336]
      end
    when 424...448
      case x
      when 272...296
        return '源下'
      when 568...592
        return '目标下'
      end
    end
    return nil
  end
end