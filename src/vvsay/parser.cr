require "option_parser"
require "./action"
require "./config"
require "./options"

module Vvsay
  class Parser < OptionParser
    getter options : Options

    property help_message : String

    # デバッグオプション用マクロ
    macro _on_debug_
      on("-d", "--debug", "エラー時にバックトレースを表示") do
        CLI.debug = true
      end
    end

    # ヘルプオプション用マクロ
    macro _on_help_
      on("-h", "--help", "ヘルプを表示") do
        @options.action = Action::Help
      end

      @help_message = self.to_s
    end

    # アクションとバナーを設定するマクロ
    macro _set_action_(action, banner)
      @options.action = {{action}}
      @handlers.clear
      @flags.clear
      self.banner = {{banner}}
    end

    # 音声合成の共通オプション用マクロ
    macro _synthesis_options_
      on("-t TEXT", "--text=TEXT", "合成するテキスト") { |t| @options.text = t }
      on("-s ID", "--speaker=ID", "話者ID (デフォルト: 1)") { |s| @options.speaker_id = s.to_i }
      on("-o FILE", "--output=FILE", "出力ファイル名 (デフォルト: output.wav)") { |o| @options.output_file = o }

      # 音声合成の詳細設定オプション
      on("-S SCALE", "--speed=SCALE", "話速のスケール (デフォルト: 1.0)") { |s| @options.speed_scale = s.to_f }
      on("-T SCALE", "--pitch=SCALE", "音高のスケール (デフォルト: 0.0)") { |p| @options.pitch_scale = p.to_f }
      on("-I SCALE", "--intonation=SCALE", "抑揚のスケール (デフォルト: 1.0)") { |i| @options.intonation_scale = i.to_f }
      on("-V SCALE", "--volume=SCALE", "音量のスケール (デフォルト: 1.0)") { |v| @options.volume_scale = v.to_f }
      on("-P", "--play", "音声合成後に自動再生する") { @options.play = true }
    end

    # 接続設定オプション用マクロ
    macro _connection_options_
      on("--host=HOST", "VOICEVOX Engine のホスト (デフォルト: #{DEFAULT_HOST})") { |h| @options.host = h }
      on("--port=PORT", "VOICEVOX Engine のポート (デフォルト: #{DEFAULT_PORT})") { |p| @options.port = p.to_i }
    end

    def initialize
      super()
      @options = Options.new
      @help_message = ""

      self.banner = <<-BANNER

      #{"Program:".colorize.green.bold} #{"VVSAY (VOICEVOX Engine を呼び出すための Crystal 製 CLI ツール)".colorize.bold}
      #{"Version:".colorize.green} #{VERSION}
      #{"Source: ".colorize.green} https://github.com/kojix2/vvsay

      #{"使用方法:".colorize.green.bold} vvsay <コマンド> [オプション]
      BANNER

      separator("\n#{"コマンド:".colorize.green.bold}")

      # speakers サブコマンド
      on("speakers", "speakers    利用可能な話者一覧を表示") do
        _set_action_(Action::Speakers, "使用方法: vvsay speakers [オプション]")

        on("--format=FORMAT", "出力形式 (text, json)") do |format|
          @options.output_format = format
        end

        on("--filter=KEYWORD", "キーワードでフィルタリング") do |keyword|
          @options.filter = keyword
        end

        _connection_options_
        _on_debug_
        _on_help_
      end

      # synthesis サブコマンド
      on("synthesis", "テキストから音声を合成") do
        _set_action_(Action::Synthesis, "使用方法: vvsay synthesis [オプション]")

        _synthesis_options_
        _connection_options_

        on("--format=FORMAT", "出力形式 (wav, mp3, ogg)") do |format|
          @options.output_format = format
        end

        on("--stdin", "標準入力からテキストを読み込む") do
          @options.stdin = true
        end

        _on_debug_
        _on_help_
      end

      # query サブコマンド（音声合成用クエリの操作）
      on("query", "音声合成用クエリの操作") do
        _set_action_(Action::Help, "使用方法: vvsay query [オプション] <サブコマンド>")

        on("create", "音声合成用クエリを作成") do
          _set_action_(Action::CreateQuery, "使用方法: vvsay query create [オプション]")

          on("-t TEXT", "--text=TEXT", "合成するテキスト") { |t| @options.text = t }
          on("-s ID", "--speaker=ID", "話者ID (デフォルト: 1)") { |s| @options.speaker_id = s.to_i }
          on("-o FILE", "--output=FILE", "出力JSONファイル名") { |o| @options.output_file = o }

          _connection_options_
          _on_debug_
          _on_help_
        end

        on("modify", "音声合成用クエリを修正") do
          _set_action_(Action::ModifyQuery, "使用方法: vvsay query modify [オプション] <クエリファイル>")

          on("-i FILE", "--input=FILE", "入力JSONファイル名") { |i| @options.input_file = i }
          on("-o FILE", "--output=FILE", "出力JSONファイル名") { |o| @options.output_file = o }

          on("-S SCALE", "--speed=SCALE", "話速のスケール") { |s| @options.speed_scale = s.to_f }
          on("-T SCALE", "--pitch=SCALE", "音高のスケール") { |p| @options.pitch_scale = p.to_f }
          on("-I SCALE", "--intonation=SCALE", "抑揚のスケール") { |i| @options.intonation_scale = i.to_f }
          on("-V SCALE", "--volume=SCALE", "音量のスケール") { |v| @options.volume_scale = v.to_f }

          _on_debug_
          _on_help_
        end

        _on_debug_
        _on_help_
      end

      separator("\n#{"一般オプション:".colorize.green.bold}")

      # メインコマンドのオプション
      _synthesis_options_ # デフォルトはsynthesisコマンドと同じオプション
      _connection_options_

      on("--stdin", "標準入力からテキストを読み込む") do
        @options.stdin = true
      end

      on("--version", "バージョンを表示") do
        @options.action = Action::Version
      end

      _on_debug_
      _on_help_

      invalid_option do |flag|
        STDERR.puts "#{"エラー:".colorize.red.bold} #{flag} は無効なオプションです。"
        STDERR.puts self
        exit(1)
      end

      missing_option do |flag|
        STDERR.puts "#{"エラー:".colorize.red.bold} #{flag} は引数が必要です。"
        STDERR.puts self
        exit(1)
      end
    end

    def parse(args : Array(String)) : Options
      super(args)

      # 残りの引数を処理
      if args.size > 0
        command = args[0]
        case command
        when "speakers"
          @options.action = Action::Speakers
        when "synthesis"
          @options.action = Action::Synthesis
        when "query"
          # queryサブコマンドは既に処理されているので何もしない
        else
          # サブコマンドが指定されていない場合は、残りの引数をテキストとして扱う
          if @options.text.empty? && !["--help", "-h", "--version", "-d", "--debug"].includes?(command)
            @options.text = args.join(" ")
          end
        end
      end

      # 標準入力からテキストを読み込む（--stdinオプションが指定されている場合、または
      # テキストが指定されておらず標準入力がパイプされている場合）
      if (@options.stdin || @options.text.empty?) && !STDIN.tty?
        @options.text = STDIN.gets_to_end.chomp
      end

      @options
    end

    def help_message : String
      @help_message
    end
  end
end
