require "crest"
require "json"
require "./parser"
require "./client"
require "./version"

module Zunsay
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
      error_message = "\n[zunsay] エラー: #{ex.class} #{ex.message}"
      error_message += "\nステータスコード: #{ex.http_code}"
      error_message += "\nレスポンス: #{ex.response.body}" if ex.response
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit 1
    rescue ex : Crest::RequestTimeout
      error_message = "\n[zunsay] エラー: VOICEVOX Engine に接続できませんでした。"
      error_message += "\nホスト #{option.host}:#{option.port} が正しいか、Engine が起動しているか確認してください。"
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit 1
    rescue ex
      error_message = "\n[zunsay] エラー: #{ex.message}"
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

        puts "名前: #{name} (UUID: #{uuid})"
        puts "スタイル:"
        styles.each do |style|
          style_name = style["name"].as_s
          style_id = style["id"].as_i
          puts "  - #{style_name} (ID: #{style_id})"
        end
        puts
      end
    end

    private def synthesize_voice
      # テキストが指定されていない場合はエラー
      if option.text.empty?
        STDERR.puts "エラー: テキストが指定されていません。-t または --text オプションでテキストを指定してください。"
        exit 1
      end

      # 音声合成の実行
      puts "テキスト「#{option.text}」を話者ID #{option.speaker_id} で合成します..."
      client = Client.new(option.host, option.port)
      query = client.audio_query(option.text, option.speaker_id)
      query = client.apply_parameters(query, option)
      
      # パラメータ情報を表示
      puts "話速: #{option.speed_scale}, 音高: #{option.pitch_scale}, 抑揚: #{option.intonation_scale}, 音量: #{option.volume_scale}"
      
      client.synthesis(query, option.speaker_id, option.output_file)
      
      # 音声再生の実行（--playオプションが指定されている場合）
      if option.play
        puts "音声を再生します..."
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
          puts "警告: 適切な音声再生コマンドが見つかりませんでした。"
        end
      end
    end

    private def print_version
      puts "zunsay version #{VERSION}"
    end

    private def print_help
      puts parser.help_message
    end

    private def create_query
      # テキストが指定されていない場合はエラー
      if option.text.empty?
        STDERR.puts "エラー: テキストが指定されていません。-t または --text オプションでテキストを指定してください。"
        exit 1
      end

      # 出力ファイルが指定されていない場合はデフォルト値を設定
      output_file = option.output_file
      if output_file == "output.wav"
        output_file = "query.json"
      end

      # 音声合成用クエリの作成
      puts "テキスト「#{option.text}」の音声合成用クエリを作成します..."
      client = Client.new(option.host, option.port)
      query = client.audio_query(option.text, option.speaker_id)
      
      # クエリをJSONファイルに保存
      File.write(output_file, query.to_json)
      puts "クエリをファイルに保存しました: #{output_file}"
    end

    private def modify_query
      # 入力ファイルが指定されていない場合はエラー
      if option.input_file.empty?
        STDERR.puts "エラー: 入力ファイルが指定されていません。-i または --input オプションで入力ファイルを指定してください。"
        exit 1
      end

      # 出力ファイルが指定されていない場合は入力ファイルを上書き
      output_file = option.output_file.empty? ? option.input_file : option.output_file

      # クエリファイルの読み込み
      puts "クエリファイル「#{option.input_file}」を読み込みます..."
      query_json = File.read(option.input_file)
      query = JSON.parse(query_json)

      # パラメータの適用
      client = Client.new(option.host, option.port)
      modified_query = client.apply_parameters(query, option)
      
      # パラメータ情報を表示
      puts "話速: #{option.speed_scale}, 音高: #{option.pitch_scale}, 抑揚: #{option.intonation_scale}, 音量: #{option.volume_scale}"
      
      # 修正したクエリをJSONファイルに保存
      File.write(output_file, modified_query.to_json)
      puts "修正したクエリをファイルに保存しました: #{output_file}"
    end
  end
end
