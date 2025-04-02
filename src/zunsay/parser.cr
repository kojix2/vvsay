require "option_parser"
require "./action"
require "./config"
require "./options"

module Zunsay
  class Parser
    getter option_parser : OptionParser
    getter options : Options

    def initialize
      @options = Options.new
      @option_parser = OptionParser.new
      @option_parser.banner = "使用方法: zunsay [オプション] [コマンド]"

      @option_parser.separator("\nコマンド:")
      @option_parser.separator("  speakers    - 利用可能な話者一覧を表示")
      @option_parser.separator("  synthesis   - テキストから音声を合成 (デフォルト)")

      @option_parser.separator("\n共通オプション:")
      @option_parser.on("-h HOST", "--host=HOST", "VOICEVOX Engine のホスト (デフォルト: #{DEFAULT_HOST})") { |h| @options.host = h }
      @option_parser.on("-p PORT", "--port=PORT", "VOICEVOX Engine のポート (デフォルト: #{DEFAULT_PORT})") { |p| @options.port = p.to_i }
      @option_parser.separator("\n音声合成オプション:")
      @option_parser.on("-t TEXT", "--text=TEXT", "合成するテキスト") { |t| @options.text = t }
      @option_parser.on("-s ID", "--speaker=ID", "話者ID (デフォルト: 1)") { |s| @options.speaker_id = s.to_i }
      @option_parser.on("-o FILE", "--output=FILE", "出力ファイル名 (デフォルト: output.wav)") { |o| @options.output_file = o }

      @option_parser.separator("\nその他:")
      @option_parser.on("--help", "ヘルプを表示") do
        @options.action = Action::Help
      end
      
      @option_parser.on("--version", "バージョンを表示") do
        @options.action = Action::Version
      end
      
      @option_parser.on("-d", "--debug", "エラー時にバックトレースを表示") do
        CLI.debug = true
      end
    end

    def parse(args : Array(String)) : Options
      # オプションをデフォルト値にリセット
      @options = Options.new

      # コマンドライン引数を解析
      @option_parser.parse(args)

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
      @option_parser.to_s
    end
  end
end
