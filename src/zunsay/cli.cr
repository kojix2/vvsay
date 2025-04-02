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
      client.synthesis(query, option.speaker_id, option.output_file)
    end

    private def print_version
      puts "zunsay version #{VERSION}"
    end

    private def print_help
      puts parser.help_message
    end
  end
end
