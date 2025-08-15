require "crest"
require "json"
require "colorize"
require "./parser"
require "./client"
require "./version"

Colorize.on_tty_only!

module VVsay
  class CLI
    class_property debug : Bool = false
    getter parser : Parser
    getter option : Options

    def initialize
      @parser = Parser.new
      @option = parser.parse(ARGV)
    end

    def run
      case option.action
      when Action::Speakers
        show_speakers
      when Action::Synthesis
        synthesize_voice
      when Action::Version
        print_version
      when Action::Help
        print_help
      when Action::CreateQuery
        create_query
      when Action::ModifyQuery
        modify_query
      else
        raise ArgumentError.new("不明なアクション: #{option.action}")
      end
    rescue ex : Crest::RequestFailed
      error_message = "\n[vvsay] #{"エラー:".colorize.red.bold} #{ex.class} #{ex.message}"
      error_message += "\n#{"ステータスコード:".colorize.yellow} #{ex.http_code}"
      error_message += "\n#{"レスポンス:".colorize.yellow} #{ex.response.body}" if ex.response
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit 1
    rescue ex : Crest::RequestTimeout
      error_message = "\n[vvsay] #{"エラー:".colorize.red.bold} VOICEVOX Engine に接続できませんでした。"
      error_message += "\nホスト #{option.host}:#{option.port} が正しいか、Engine が起動しているか確認してください。"
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit 1
    rescue ex
      error_message = "\n[vvsay] #{"エラー:".colorize.red.bold} #{ex.message}"
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit 1
    end

    private def show_speakers
      client = Client.new(option.host, option.port)
      speakers = client.speakers
      speakers.as_a.each do |speaker|
        name = speaker["name"].as_s
        uuid = speaker["speaker_uuid"].as_s
        styles = speaker["styles"].as_a

        puts "#{"名前:".colorize.blue.bold} #{name.colorize.blue} (UUID: #{uuid.colorize(:dark_gray)})"
        puts "#{"スタイル:".colorize.cyan.bold}"
        styles.each do |style|
          style_name = style["name"].as_s
          style_id = style["id"].as_i
          puts "  - #{style_name.colorize.cyan} (ID: #{style_id.to_s.colorize(:dark_gray)})"
        end
        puts
      end
    end

    private def synthesize_voice
      # テキストが指定されていない場合はエラー
      if option.text.empty?
        STDERR.puts "#{"エラー:".colorize.red.bold} テキストが指定されていません。-t または --text オプションでテキストを指定してください。"
        exit 1
      end

      # 音声合成の実行
      puts "#{"テキスト".colorize.green.bold}「#{option.text.colorize.bold}」を#{"話者ID".colorize.magenta.bold} #{option.speaker_id.to_s.colorize.magenta} で合成します..."
      client = Client.new(option.host, option.port)
      query = client.audio_query(option.text, option.speaker_id)
      query = client.apply_parameters(query, option)

      # パラメータ情報を表示
      puts "#{"話速:".colorize.yellow} #{option.speed_scale.to_s.colorize.light_yellow}, " +
           "#{"音高:".colorize.blue} #{option.pitch_scale.to_s.colorize.light_blue}, " +
           "#{"抑揚:".colorize.magenta} #{option.intonation_scale.to_s.colorize.light_magenta}, " +
           "#{"音量:".colorize.cyan} #{option.volume_scale.to_s.colorize.light_cyan}"

      client.synthesis(query, option.speaker_id, option.output_file)

      # 成功メッセージ
      puts "#{"成功:".colorize.green.bold} 音声ファイルを保存しました: #{option.output_file.colorize.green}"

      # 音声再生の実行（--playオプションが指定されている場合）
      if option.play
        puts "#{"再生:".colorize.blue.bold} 音声を再生します..."
        case
        when system("which afplay >/dev/null 2>&1") # macOS
          system("afplay #{option.output_file}")
        when system("which aplay >/dev/null 2>&1") # Linux
          system("aplay #{option.output_file}")
        when system("which paplay >/dev/null 2>&1") # PulseAudio
          system("paplay #{option.output_file}")
        when system("which powershell >/dev/null 2>&1") # Windows
          system(%Q(powershell -c (New-Object Media.SoundPlayer "#{option.output_file}").PlaySync()))
        else
          puts "#{"警告:".colorize.yellow.bold} 適切な音声再生コマンドが見つかりませんでした。"
        end
      end
    end

    private def print_version
      puts "#{"vvsay".colorize.magenta.bold} version #{VERSION.colorize.light_magenta}"
    end

    private def print_help
      puts parser.help_message
    end

    private def create_query
      # テキストが指定されていない場合はエラー
      if option.text.empty?
        STDERR.puts "#{"エラー:".colorize.red.bold} テキストが指定されていません。-t または --text オプションでテキストを指定してください。"
        exit 1
      end

      # 出力ファイルが指定されていない場合はデフォルト値を設定
      output_file = option.output_file
      if output_file == "output.wav"
        output_file = "query.json"
      end

      # 音声合成用クエリの作成
      puts "#{"テキスト".colorize.green.bold}「#{option.text.colorize.bold}」の音声合成用クエリを作成します..."
      client = Client.new(option.host, option.port)
      query = client.audio_query(option.text, option.speaker_id)

      # クエリをJSONファイルに保存
      File.write(output_file, query.to_json)
      puts "#{"成功:".colorize.green.bold} クエリをファイルに保存しました: #{output_file.colorize.green}"
    end

    private def modify_query
      # 入力ファイルが指定されていない場合はエラー
      if option.input_file.empty?
        STDERR.puts "#{"エラー:".colorize.red.bold} 入力ファイルが指定されていません。-i または --input オプションで入力ファイルを指定してください。"
        exit 1
      end

      # 出力ファイルが指定されていない場合は入力ファイルを上書き
      output_file = option.output_file.empty? ? option.input_file : option.output_file

      # クエリファイルの読み込み
      puts "#{"読込:".colorize.blue.bold} クエリファイル「#{option.input_file.colorize.blue}」を読み込みます..."
      query_json = File.read(option.input_file)
      query = JSON.parse(query_json)

      # パラメータの適用
      client = Client.new(option.host, option.port)
      modified_query = client.apply_parameters(query, option)

      # パラメータ情報を表示
      puts "#{"話速:".colorize.yellow} #{option.speed_scale.to_s.colorize.light_yellow}, " +
           "#{"音高:".colorize.blue} #{option.pitch_scale.to_s.colorize.light_blue}, " +
           "#{"抑揚:".colorize.magenta} #{option.intonation_scale.to_s.colorize.light_magenta}, " +
           "#{"音量:".colorize.cyan} #{option.volume_scale.to_s.colorize.light_cyan}"

      # 修正したクエリをJSONファイルに保存
      File.write(output_file, modified_query.to_json)
      puts "#{"成功:".colorize.green.bold} 修正したクエリをファイルに保存しました: #{output_file.colorize.green}"
    end
  end
end
