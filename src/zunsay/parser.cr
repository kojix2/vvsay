require "option_parser"
require "./action"
require "./config"
require "./options"

module Zunsay
  class Parser < OptionParser
    getter options : Options

    def initialize
      super()
      @options = Options.new
      self.banner = "使用方法: zunsay [オプション] [コマンド]"

      separator("\nコマンド:")
      separator("  speakers    - 利用可能な話者一覧を表示")
      separator("  synthesis   - テキストから音声を合成 (デフォルト)")

      separator("\n共通オプション:")
      on("-h HOST", "--host=HOST", "VOICEVOX Engine のホスト (デフォルト: #{DEFAULT_HOST})") { |h| @options.host = h }
      on("-p PORT", "--port=PORT", "VOICEVOX Engine のポート (デフォルト: #{DEFAULT_PORT})") { |p| @options.port = p.to_i }
      separator("\n音声合成オプション:")
      on("-t TEXT", "--text=TEXT", "合成するテキスト") { |t| @options.text = t }
      on("-s ID", "--speaker=ID", "話者ID (デフォルト: 1)") { |s| @options.speaker_id = s.to_i }
      on("-o FILE", "--output=FILE", "出力ファイル名 (デフォルト: output.wav)") { |o| @options.output_file = o }

      # 音声合成の詳細設定オプション
      on("--speed=SCALE", "話速のスケール (デフォルト: 1.0)") { |s| @options.speed_scale = s.to_f }
      on("--pitch=SCALE", "音高のスケール (デフォルト: 0.0)") { |p| @options.pitch_scale = p.to_f }
      on("--intonation=SCALE", "抑揚のスケール (デフォルト: 1.0)") { |i| @options.intonation_scale = i.to_f }
      on("--volume=SCALE", "音量のスケール (デフォルト: 1.0)") { |v| @options.volume_scale = v.to_f }

      separator("\nその他:")
      on("--help", "ヘルプを表示") do
        @options.action = Action::Help
      end

      on("--version", "バージョンを表示") do
        @options.action = Action::Version
      end

      on("-d", "--debug", "エラー時にバックトレースを表示") do
        CLI.debug = true
      end

      invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} は無効なオプションです。"
        STDERR.puts self
        exit(1)
      end

      missing_option do |flag|
        STDERR.puts "ERROR: #{flag} は引数が必要です。"
        STDERR.puts self
        exit(1)
      end
    end

    def parse(args : Array(String)) : Options
      super()

      # 残りの引数を処理
      if args.size > 0
        command = args[0]
        case command
        when "speakers"
          @options.action = Action::Speakers
        when "synthesis"
          @options.action = Action::Synthesis
        else
          raise ArgumentError.new("不明なコマンド: #{command}")
        end
      end

      @options
    end

    def help_message : String
      to_s
    end
  end
end
