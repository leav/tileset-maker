#==============================================================================
# ■ Scene_Tileset
#------------------------------------------------------------------------------
# 　处理合成器画面的类。
#==============================================================================

class Scene_Tileset
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    # 载入数据库
    #$data_actors        = load_data("Data/Actors.rxdata")
    #$data_classes       = load_data("Data/Classes.rxdata")
    #$data_skills        = load_data("Data/Skills.rxdata")
    #$data_items         = load_data("Data/Items.rxdata")
    #$data_weapons       = load_data("Data/Weapons.rxdata")
    #$data_armors        = load_data("Data/Armors.rxdata")
    #$data_enemies       = load_data("Data/Enemies.rxdata")
    #$data_troops        = load_data("Data/Troops.rxdata")
    #$data_states        = load_data("Data/States.rxdata")
    #$data_animations    = load_data("Data/Animations.rxdata")
    if PATH != ""
      $data_tilesets = load_data(PATH + "/Data/Tilesets.rxdata")
    else
      $data_tilesets = load_data("Data/Tilesets.rxdata")
    end
    #$data_common_events = load_data("Data/CommonEvents.rxdata")
    $data_system        = load_data("Data/System.rxdata")
    # 生成系统对像
    $game_system = Game_System.new
    # 鼠标之前是否按下
    @mouse_press = false
    # 初始化记忆数组
    @undo_steps = []
    @redo_steps = []
    # 生成背景窗口
    @back_window = Window_Back.new
    # 源图块viewport
    source_viewport = Viewport.new(32, 80, 256, 384)
    source_viewport.z = 200
    # 源图块选框
    @source_rect = Window.new(source_viewport)
    @source_rect.windowskin = RPG::Cache.windowskin($game_system.windowskin_name)
    @source_rect.width = 32
    @source_rect.height = 32
    @source_rect.back_opacity = 0
    @source_rect.z = 100
    @source_rect.visible = false
    # 源图块精灵
    @source_tileset_sprite = Sprite.new(source_viewport)
    @source_tileset_sprite.bitmap = Bitmap.new(256, 32)
    # 源图块背景精灵
    back_viewport = Viewport.new(32, 80, 256, 384)
    back_viewport.z = 100
    @source_tileset_back_sprite = Sprite.new(back_viewport)
    @source_tileset_back_sprite.x = 0
    @source_tileset_back_sprite.y = 0
    @source_tileset_back_sprite.bitmap = Bitmap.new(256, 32)
    @source_tileset_back_sprite.bitmap.fill_rect(0, 0, 256, 32, VIEW_BACK_COLOR)
    # 目标图块viewport
    @target_viewport = Viewport.new(328, 80, 256, 384)
    @target_viewport.z = 200
    # 目标图块选框
    @target_rect = Window.new(@target_viewport)
    @target_rect.windowskin = RPG::Cache.windowskin($game_system.windowskin_name)
    @target_rect.width = 32
    @target_rect.height = 32
    @target_rect.z = 100
    @target_rect.back_opacity = 0
    @target_rect.visible = false
    # 目标图块精灵数组
    @target_tileset_top_y = 0
    @target_tileset_sprites = []
    # 目标图块背景精灵
    back_viewport = Viewport.new(328, 80, 256, 384)
    back_viewport.z = 100
    @target_tileset_back_sprite = Sprite.new(back_viewport)
    @target_tileset_back_sprite.x = 0
    @target_tileset_back_sprite.y = 0
    @target_tileset_back_sprite.bitmap = Bitmap.new(256, 32)
    @target_tileset_back_sprite.bitmap.fill_rect(0, 0, 256, 32, VIEW_BACK_COLOR)
    # 目标图块资料数组
    @target_tileset_data = []
    # 设置目标图块
    set_target_tileset_height(12)
    # 检查是否存在恢复文件
    if FileTest.exist?('Recover.rxdata')
      @recover_window = Window_Recover.new
    end
    # 执行过渡
    Graphics.transition
    # 主循环
    loop do
      # 刷新游戏画面
      Graphics.update
      # 刷新输入信息
      Input.update
      # 刷新画面
      update
      # 如果画面被切换的话就中断循环
      if $scene != self
        break
      end
    end
    # 准备过渡
    Graphics.freeze
    # 释放窗口
    @back_window.dispose
    @source_tileset_sprite.dispose
    @source_rect.dispose
    @source_tileset_back_sprite.dispose
    @target_viewport.dispose
    for sprite in @target_tileset_sprites
      next if sprite == nil
      sprite.dispose
    end
    @target_rect.dispose
    @target_tileset_back_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    if @recover_window != nil
      update_recover_window
      return
    end
    if @copytype_window != nil
      update_copytype_window
      return
    end
    if @open_command_window != nil
      update_open_command_window
      return
    end
    if @output_window != nil
      update_output_window
      return
    end
    update_main
  end
  #--------------------------------------------------------------------------
  # ● 主界面刷新
  #--------------------------------------------------------------------------
  def update_main
    # 刷新按钮
    if @last_source_visible != @source_rect.visible or
      @last_target_visible != @target_rect.visible
      refresh_buttons
      @last_source_visible = @source_rect.visible
      @last_target_visible = @target_rect.visible
    end
    # 按下 A 键的情况下
    if Input.press?(Input::A)
      # 隐藏背景窗口
      @back_window.visible = false
      @source_tileset_back_sprite.visible = false
      @target_tileset_back_sprite.visible = false
    else
      @back_window.visible = true
      @source_tileset_back_sprite.visible = true
      @target_tileset_back_sprite.visible = true
    end
    # 按下 C 键的情况下
    if Input.trigger?(Input::C)
      # 取得鼠标位置
      mouse_x, mouse_y = Mouse.get_mouse_pos
      mouse_x -= @back_window.x + 16
      mouse_y -= @back_window.y + 16
      command = @back_window.command(mouse_x, mouse_y)
      case command
      when '撤消'
        if @undo_steps.size > 0
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          store_redo
          undo_step
          # 刷新按钮
          refresh_buttons
        end
      when '恢复'
        if @redo_steps.size > 0
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          store_undo(false)
          redo_step
          # 刷新按钮
          refresh_buttons
        end
      when '粘贴'
        if (@source_tileset_data != nil and @source_rect.visible and @target_rect.visible and
    @source_rect.y + @source_rect.height - @source_tileset_sprite.y <= @source_tileset_sprite.bitmap.height)
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          copy_tileset(0)
          # 刷新按钮
          refresh_buttons
          return
        end
      when '特殊粘贴..'
        if (@source_tileset_data != nil and @source_rect.visible and @target_rect.visible and
    @source_rect.y + @source_rect.height - @source_tileset_sprite.y <= @source_tileset_sprite.bitmap.height)
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          @copytype_window = Window_CopyType.new(184, 48, 150, ['仅粘贴数据', '仅粘贴图片'])
          @copytype_window.z = 200
          return
        end
      when '清除'
        if @target_rect.visible and @target_rect.y - @target_tileset_top_y < @target_tileset_sprites.size / 8 * 32
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          store_undo
          target_pos = (@target_rect.y - @target_tileset_top_y) / 32 * 8 + @target_rect.x / 32
          @target_tileset_sprites[target_pos].bitmap.clear
          @target_tileset_data[target_pos] = [0, 0]
          # 刷新按钮
          refresh_buttons
          return
        end
      when '增加高度'
        store_undo
        set_target_tileset_height(@target_tileset_sprites.size / 8 + 1)
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 刷新按钮
        refresh_buttons
        return
      when '减少高度'
        if @target_tileset_sprites.size > 8
          store_undo
          set_target_tileset_height(@target_tileset_sprites.size / 8 - 1)
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          # 刷新按钮
          refresh_buttons
          return
        end
      when '打开..'
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 打开窗口
        @open_command_window = Window_OpenCommand.new($data_tilesets.compact)
        return
      when '导出..'
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 打开窗口
        @output_window = Window_Output.new($data_tilesets)
        return
      end
    end
    # 之前鼠标已在源窗口按下的情况下
    if @mouse_press
      # 鼠标拖动
      if Input.press?(Input::C)
        # 取得鼠标位置
        mouse_x, mouse_y = Mouse.get_mouse_pos
        mouse_x -= 32
        mouse_y -= 80
        if mouse_x >= 0 and mouse_x < 256 and mouse_y >= 0 and mouse_y < 384
          if mouse_x < @source_rect.x
            @source_rect.x = mouse_x / 32 * 32
          end
          if mouse_y < @source_rect.y
            @source_rect.y = mouse_y / 32 * 32
          end
          @source_rect.width = 32 + (mouse_x - @source_rect.x) / 32 * 32
          @source_rect.height = 32 + (mouse_y - @source_rect.y) / 32 * 32
          @target_rect.width = @source_rect.width
          @target_rect.height = @source_rect.height
          if Graphics.frame_count % 5 == 0 and mouse_y >= 352 and
            (@source_rect.height > 32 or @source_rect.width > 32)
            source_tileset_sprite_move(-32)
          end
        end
      # 放开鼠标
      else
        @mouse_press = false
      end
    # 之前未按下的情况下
    else
      # 按下的情况下
      if Input.press?(Input::C)
        # 取得鼠标位置
        mouse_x, mouse_y = Mouse.get_mouse_pos
        mouse_x -= 32
        mouse_y -= 80
        # 在图块的高度的情况下
        if mouse_y >= 0 and mouse_y < 384
          # 源图块
          if mouse_x >= 0 and mouse_x < 256
            @source_rect.x = mouse_x / 32 * 32
            @source_rect.y = mouse_y / 32 * 32
            @source_rect.width = 32
            @source_rect.height = 32
            @source_rect.visible = true
            @mouse_press = true
            # 刷新按钮
            refresh_buttons
          # 目标图块
          elsif mouse_x >= 296 and mouse_x < 552
            @target_rect.x = (mouse_x - 296) / 32 * 32
            @target_rect.y = mouse_y / 32 * 32
            @target_rect.width = @source_rect.width
            @target_rect.height = @source_rect.height
            @target_rect.visible = true
            # 刷新按钮
            refresh_buttons
          end
        end
        mouse_x -= @back_window.x + 16 - 32
        mouse_y -= @back_window.y + 16 - 80
        command = @back_window.command(mouse_x, mouse_y)
        case command
        when '源上'
          source_tileset_sprite_move(32)
          return
        when '源下'
          source_tileset_sprite_move(-32)
          return
        when '目标上'
          target_tileset_sprite_move(32)
          return
        when '目标下'
          target_tileset_sprite_move(-32)
          return
        else
          if command.is_a?(Array)
            case command[0]
            when '源'
              distance = - (@source_tileset_sprite.y - 16 +
              (@source_tileset_sprite.bitmap.height - 384) * command[1] / 100) / 32 * 32
              source_tileset_sprite_move(distance)
              return
            when '目标'
              distance = - (@target_tileset_top_y - 16 +
              (@target_tileset_sprites.size / 8 * 32 - 384) * command[1] / 100) / 32 * 32
              target_tileset_sprite_move(distance)
              return
            end
          end
        end
      end
    end
    # 按下 B 键的情况下
    if Input.trigger?(Input::B)
      # 重置选框
      reset_rects
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新恢复窗口
  #--------------------------------------------------------------------------
  def update_recover_window
    # C 键被按下的情况下
    if Input.trigger?(Input::C)
      mouse_x, mouse_y = Mouse.get_mouse_pos
      mouse_x -= @recover_window.x + 16
      mouse_y -= @recover_window.y + 16
      if @recover_window.command(mouse_x, mouse_y) == '是'
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 读取数据
        tileset_data = load_data('Recover.rxdata')
        # 设置高度
        set_target_tileset_height(tileset_data.size / 8)
        @target_tileset_data = tileset_data
        # 设置图块
        for i in 0...tileset_data.size
          data = tileset_data[i]
          # 防止过长时间没有刷新
          if Time.now.strftime('%M%S').to_i - $last_time > 5
            Graphics.update
            $last_time = Time.now.strftime('%M%S').to_i
          end
          next if data[0] == 0
          tileset = Tileset_Maker.bitmap($data_tilesets[data[0]].tileset_name)
          x = (data[1] - 384) % 8 * 32
          y = (data[1] - 384) / 8 * 32
          @target_tileset_sprites[i].bitmap.blt(0, 0, tileset, Rect.new(x, y, 32, 32))
        end
        # 关闭窗口
        @recover_window.dispose
        @recover_window = nil
      elsif @recover_window.command(mouse_x, mouse_y) == '否'
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 关闭窗口
        @recover_window.dispose
        @recover_window = nil
      end
      return
    end
    # B 键被按下的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      # 关闭窗口
      @recover_window.dispose
      @recover_window = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新特殊粘贴
  #--------------------------------------------------------------------------
  def update_copytype_window
    @copytype_window.update
    # C 键被按下的情况下
    if Input.trigger?(Input::C)
      mouse_x, mouse_y = Mouse.get_mouse_pos
      mouse_x -= @copytype_window.x + 16
      mouse_y -= @copytype_window.y + 16
      if @copytype_window.command(mouse_x, mouse_y) == '确定'
        if @copytype_window.item != nil
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
          copy_tileset(@copytype_window.index + 1)
          # 关闭窗口
          @copytype_window.visible = false
          @copytype_window.dispose
          @copytype_window = nil
        end
      end
    end
    # B 键被按下的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      # 关闭窗口
      @copytype_window.visible = false
      @copytype_window.dispose
      @copytype_window = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新打开命令
  #--------------------------------------------------------------------------
  def update_open_command_window
    @open_command_window.update
    # C 键被按下的情况下
    if Input.trigger?(Input::C)
      mouse_x, mouse_y = Mouse.get_mouse_pos
      mouse_x -= @open_command_window.x + 16
      mouse_y -= @open_command_window.y + 16
      case mouse_y
      when 336..368
        case mouse_x
        # 确认
        when 144..208
          if @open_command_window.index >= 0 and @open_command_window.item != nil
            # 演奏确定 SE
            $game_system.se_play($data_system.decision_se)
            # 记录源图块数据
            @source_tileset_data = @open_command_window.item
            # 重置选框
            reset_rects
            # 刷新源图块精灵
            refresh_source_tileset_sprite
            # 关闭窗口
            @open_command_window.visible = false
            @open_command_window.dispose
            @open_command_window = nil
          end
        end
      end
    end
    # B 键被按下的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      # 关闭窗口
      @open_command_window.visible = false
      @open_command_window.dispose
      @open_command_window = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新导出
  #--------------------------------------------------------------------------
  def update_output_window
    @output_window.update
    if @type_field != nil
      @type_field.update
    end
    # C 键被按下的情况下
    if Input.trigger?(Input::C)
      # 如果输入域存在的话
      if @type_field != nil
        # 演奏确定 SE
        $game_system.se_play($data_system.decision_se)
        # 导出数据
        tileset_name = @type_field.get_text
        table_size = 384 + @target_tileset_sprites.size
        data = @output_window.data.clone
        # 关闭输入域
        @type_field.dispose
        @type_field = nil
        @type_window.dispose
        @type_window = nil
        if @output_window.index >= data.size
          for i in data.size..@output_window.index
            data[i] = RPG::Tileset.new
          end
        end
        data[@output_window.index].id = @output_window.index
        data[@output_window.index].name = tileset_name
        data[@output_window.index].tileset_name = tileset_name
        data[@output_window.index].passages = Table.new(table_size)
        data[@output_window.index].priorities = Table.new(table_size)
        data[@output_window.index].priorities[0] = 5
        data[@output_window.index].terrain_tags = Table.new(table_size)
        @output_window.draw_text('处理图块数据中...')
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
        for i in 0...@target_tileset_sprites.size
          # 防止过长时间没有刷新
          if Time.now.strftime('%M%S').to_i - $last_time > 5
            Graphics.update
            $last_time = Time.now.strftime('%M%S').to_i
          end
          tileset_id, tile_id = @target_tileset_data[i]
          next if tileset_id == 0
          data[@output_window.index].passages[384 + i] = data[tileset_id].passages[tile_id]
          data[@output_window.index].priorities[384 + i] = data[tileset_id].priorities[tile_id]
          data[@output_window.index].terrain_tags[384 + i] = data[tileset_id].terrain_tags[tile_id]
        end
        if PATH != ""
          path = PATH + "/Data/Tilesets.rxdata"
        else
          path = "Data/Tilesets.rxdata"
        end
        save_data(data, path)
        # 导出图片
        @output_window.draw_text('处理图片中...')
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
        tileset = Bitmap.new(256, @target_tileset_sprites.size / 8 * 32)
        tileset.fill_rect(0, 0, 256, tileset.height, OUTPUT_BACK_COLOR)
        x = 0
        y = 0
        src_rect = Rect.new(0, 0, 32, 32)
        for sprite in @target_tileset_sprites
          # 防止过长时间没有刷新
          if Time.now.strftime('%M%S').to_i - $last_time > 5
            Graphics.update
            $last_time = Time.now.strftime('%M%S').to_i
          end
          # 不透明化处理
          bitmap = sprite.bitmap.clone
          if OUTPUT_ALPHA_255
            for bitmap_x in 0...32
              for bitmap_y in 0...32
                color = bitmap.get_pixel(bitmap_x,bitmap_y)
                if color.alpha != 255
                  color.set(color.red, color.green, color.blue, 255)
                  bitmap.set_pixel(bitmap_x,bitmap_y,color)
                end
              end
            end
          end
          tileset.blt(x, y, bitmap, src_rect)
          x += 32
          if x >= 256
            x = 0
            y += 32
          end
        end
        @output_window.draw_text('导出图片中...')
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
        threads = []
        threads[0] = Thread.new {
        loop do
          # 防止过长时间没有刷新
          if Time.now.strftime('%M%S').to_i - $last_time > 3
            Graphics.update
            $last_time = Time.now.strftime('%M%S').to_i
          end
        end
        }
        threads[1] = Thread.new {
        tileset.make_bmp_file(tileset_name, 'Tilesets/')
        threads[0].exit
        }
        threads.each { |aThread|  aThread.join }
        #tileset.make_bmp_file(tileset_name, 'Tilesets/')
        # 关闭窗口
        @output_window.visible = false
        @output_window.dispose
        @output_window = nil
        # 删除恢复文件
        File.delete('Recover.rxdata')
      # 选择确定的话
      else
        mouse_x, mouse_y = Mouse.get_mouse_pos
        mouse_x -= @output_window.x + 16
        mouse_y -= @output_window.y + 16
        if @output_window.command(mouse_x, mouse_y) == '确定'
          # 创建输入域
          viewport = Viewport.new(112,244,472,20)
          viewport.z += 500
          @type_field = Type_Field.new(viewport, "#{Time.now.month}月#{Time.now.mday}日#{Time.now.hour}时#{Time.now.min}分#{Time.now.sec}秒",
          nil, 16, Color.new(255, 255, 255))
          @type_field.active = true
          @type_window = Window_Base.new(104, 240, 488, 28)
          @type_window.z = 200
          @type_window.opacity = 160
          # 演奏确定 SE
          $game_system.se_play($data_system.decision_se)
        end
      end
    end
    # B 键被按下的情况下
    if Input.trigger?(Input::B)
      # 演奏取消 SE
      $game_system.se_play($data_system.cancel_se)
      # 如果输入域存在的话
      if @type_field != nil
        @type_field.dispose
        @type_field = nil
        @type_window.dispose
        @type_window = nil
      else
        # 关闭窗口
        @output_window.visible = false
        @output_window.dispose
        @output_window = nil
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置选框
  #--------------------------------------------------------------------------
  def reset_rects
    @source_rect.x = 0
    @source_rect.y = 0
    @source_rect.width = 32
    @source_rect.height = 32
    @source_rect.visible = false
    @target_rect.x = 0
    @target_rect.y = 0
    @target_rect.width = 32
    @target_rect.height = 32
    @target_rect.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 刷新按钮
  #--------------------------------------------------------------------------
  def refresh_buttons
    undo_val = (@undo_steps.size > 0)
    redo_val = (@redo_steps.size > 0)
    paste = (@source_tileset_data != nil and @source_rect.visible and @target_rect.visible and
    @source_rect.y + @source_rect.height - @source_tileset_sprite.y <= @source_tileset_sprite.bitmap.height)
    clear = (@target_rect.visible and @target_rect.y - @target_tileset_top_y < @target_tileset_sprites.size / 8 * 32)
    reduce_height = @target_tileset_sprites.size > 8
    @back_window.refresh(undo_val, redo_val, paste, clear, reduce_height)
  end
  #--------------------------------------------------------------------------
  # ● 刷新源图块精灵
  #--------------------------------------------------------------------------
  def refresh_source_tileset_sprite
    if @source_tileset_sprite.bitmap != nil
      @source_tileset_sprite.bitmap.dispose
      @source_tileset_sprite.bitmap = nil
    end
    @source_tileset_sprite.bitmap = Tileset_Maker.bitmap(@source_tileset_data.tileset_name)
    @source_tileset_sprite.y = 0
    @source_tileset_back_sprite.zoom_y = @source_tileset_sprite.bitmap.height / 32
    @source_tileset_back_sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 移动源图块精灵（包含背景和选框）
  #--------------------------------------------------------------------------
  def source_tileset_sprite_move(distance)
    old_y = @source_tileset_sprite.y
    @source_tileset_sprite.y =
    [[@source_tileset_sprite.y + distance, [384 - @source_tileset_sprite.bitmap.height, 0].min].max, 0].min
    @source_tileset_back_sprite.y = @source_tileset_sprite.y
    @source_rect.y += @source_tileset_sprite.y - old_y
  end
  #--------------------------------------------------------------------------
  # ● 移动目标图块精灵（包含背景和选框）
  #--------------------------------------------------------------------------
  def target_tileset_sprite_move(distance)
    old_y = @target_tileset_top_y
    @target_tileset_top_y = 
    [[@target_tileset_top_y + distance, [384 - @target_tileset_sprites.size / 8 * 32, 0].min].max, 0].min
    for i in 0...@target_tileset_sprites.size
      @target_tileset_sprites[i].y = @target_tileset_top_y + i / 8 * 32
    end
    @target_tileset_back_sprite.y = @target_tileset_top_y
    @target_rect.y += @target_tileset_top_y - old_y
  end
  #--------------------------------------------------------------------------
  # ● 设置目标图块高度
  #--------------------------------------------------------------------------
  def set_target_tileset_height(height)
    # 增加高度的话
    if height * 8 > @target_tileset_sprites.size
      for i in @target_tileset_sprites.size...(height * 8)
        @target_tileset_sprites[i] = Sprite.new(@target_viewport)
        @target_tileset_sprites[i].x = i % 8 * 32
        @target_tileset_sprites[i].y = @target_tileset_top_y + i / 8 * 32
        @target_tileset_sprites[i].bitmap = Bitmap.new(32, 32)
        @target_tileset_data[i] = [0, 0]
      end
    # 减少高度的话
    elsif height * 8 < @target_tileset_sprites.size
      for i in (height * 8)...@target_tileset_sprites.size
        @target_tileset_sprites.pop.dispose
        @target_tileset_data.pop
      end
    end
    @target_tileset_back_sprite.zoom_y = [@target_tileset_sprites.size / 8, 1].max
  end
  #--------------------------------------------------------------------------
  # ● 粘贴图块数据
  # type : 0 全部 1 仅数据库 2 仅图片
  #--------------------------------------------------------------------------
  def copy_tileset(type)
    store_undo
    set_target_tileset_height(
    [(@target_rect.y + @target_rect.height - @target_tileset_top_y) / 32, @target_tileset_sprites.size / 8].max)
    rect_x = @source_rect.x / 32
    rect_y = (@source_rect.y - @source_tileset_sprite.y) / 32
    rect_width = @source_rect.width / 32
    rect_height = @source_rect.height / 32
    for x in rect_x...(rect_x + rect_width)
      for y in rect_y...(rect_y + rect_height)
        next if @target_rect.x / 32 + x - rect_x >= 8
        tile_id = 384 + y * 8 + x
        tileset_id = @source_tileset_data.id
        tileset_name = @source_tileset_data.tileset_name
        target_pos = ((@target_rect.y - @target_tileset_top_y) / 32 + y - rect_y) * 8 + @target_rect.x / 32 + x - rect_x
        if type == 0 or type == 2
          @target_tileset_sprites[target_pos].bitmap.clear
          bitmap = RPG::Cache.tile(tileset_name, tile_id, 0) 
          src_rect = Rect.new(0, 0, 32, 32)
          @target_tileset_sprites[target_pos].bitmap.blt(0, 0, bitmap, src_rect)
        end
        if type == 0 or type == 1
          @target_tileset_data[target_pos] = [tileset_id, tile_id]
        end
      end
    end
    # 备份数据
    save_data(@target_tileset_data, 'Recover.rxdata')
  end
  #--------------------------------------------------------------------------
  # ● 记忆操作（撤消）
  #--------------------------------------------------------------------------
  def store_undo(clear_redo_steps = true)
    # 删除超出范围的数据
    while @undo_steps.size >= MAX_STEP
      @undo_steps.shift
    end
    # 清除恢复数据
    @redo_steps = [] if clear_redo_steps
    # 记忆数据
    tileset_data = []
    for i in 0...@target_tileset_data.size
      tileset_data[i] = @target_tileset_data[i].clone
    end
    tileset = Bitmap.new(256, @target_tileset_sprites.size / 8 * 32)
    tileset.fill_rect(0, 0, 256, tileset.height, Color.new(0,0,0,0))
    x = 0
    y = 0
    src_rect = Rect.new(0, 0, 32, 32)
    for sprite in @target_tileset_sprites
      # 防止过长时间没有刷新
      if Time.now.strftime('%M%S').to_i - $last_time > 5
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
      end
      tileset.blt(x, y, sprite.bitmap, src_rect)
      x += 32
      if x >= 256
        x = 0
        y += 32
      end
    end
    @undo_steps.push([tileset_data, tileset])
  end
  #--------------------------------------------------------------------------
  # ● 记忆操作（恢复）
  #--------------------------------------------------------------------------
  def store_redo
    tileset_data = []
    for i in 0...@target_tileset_data.size
      tileset_data[i] = @target_tileset_data[i].clone
    end
    tileset = Bitmap.new(256, @target_tileset_sprites.size / 8 * 32)
    tileset.fill_rect(0, 0, 256, tileset.height, Color.new(0,0,0,0))
    x = 0
    y = 0
    src_rect = Rect.new(0, 0, 32, 32)
    for sprite in @target_tileset_sprites
      # 防止过长时间没有刷新
      if Time.now.strftime('%M%S').to_i - $last_time > 5
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
      end
      tileset.blt(x, y, sprite.bitmap, src_rect)
      x += 32
      if x >= 256
        x = 0
        y += 32
      end
    end
    @redo_steps.push([tileset_data, tileset])
  end
  #--------------------------------------------------------------------------
  # ● 撤消
  #--------------------------------------------------------------------------
  def undo_step
    tileset_data, tileset = @undo_steps.pop
    set_target_tileset_height(tileset_data.size / 8)
    for i in 0...tileset_data.size
      # 防止过长时间没有刷新
      if Time.now.strftime('%M%S').to_i - $last_time > 5
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
      end
      @target_tileset_data[i] = tileset_data[i].clone
      @target_tileset_sprites[i].bitmap.clear
      x = i % 8 * 32
      y = i / 8 * 32
      @target_tileset_sprites[i].bitmap.blt(0, 0, tileset, Rect.new(x, y, 32, 32))
    end
  end
  #--------------------------------------------------------------------------
  # ● 恢复
  #--------------------------------------------------------------------------
  def redo_step
    tileset_data, tileset = @redo_steps.pop
    set_target_tileset_height(tileset_data.size / 8)
    for i in 0...tileset_data.size
      # 防止过长时间没有刷新
      if Time.now.strftime('%M%S').to_i - $last_time > 5
        Graphics.update
        $last_time = Time.now.strftime('%M%S').to_i
      end
      @target_tileset_data[i] = tileset_data[i].clone
      @target_tileset_sprites[i].bitmap.clear
      x = i % 8 * 32
      y = i / 8 * 32
      @target_tileset_sprites[i].bitmap.blt(0, 0, tileset, Rect.new(x, y, 32, 32))
    end
  end
end
# 记录时间
$last_time = Time.now.strftime('%M%S').to_i
