module Zunsay
  # API クライアントクラス
  class Client
    getter host : String
    getter port : Int32

    def initialize(@host = DEFAULT_HOST, @port = DEFAULT_PORT)
    end

    # API のベース URL を返す
    def base_url
      "http://#{@host}:#{@port}"
    end

    # スピーカー一覧を取得する
    def speakers
      response = Crest.get("#{base_url}/speakers")
      JSON.parse(response.body)
    end

    # 音声合成用のクエリを作成する
    def audio_query(text : String, speaker_id : Int32)
      response = Crest.post(
        "#{base_url}/audio_query?text=#{URI.encode_www_form(text)}&speaker=#{speaker_id}"
      )
      JSON.parse(response.body)
    end

    # 音声合成用のクエリにパラメータを適用する
    def apply_parameters(query : JSON::Any, options : Options) : JSON::Any
      query_hash = query.as_h
      query_hash["speedScale"] = JSON::Any.new(options.speed_scale)
      query_hash["pitchScale"] = JSON::Any.new(options.pitch_scale)
      query_hash["intonationScale"] = JSON::Any.new(options.intonation_scale)
      query_hash["volumeScale"] = JSON::Any.new(options.volume_scale)
      JSON::Any.new(query_hash.to_json)
    end

    # 音声合成を実行する
    def synthesis(audio_query : JSON::Any, speaker_id : Int32, output_file : String)
      # Crest::Resource を使用してリクエストを行う
      resource = Crest::Resource.new(
        "#{base_url}",
        headers: {"Content-Type" => "application/json", "Accept" => "audio/wav"}
      )

      response = resource.post(
        "/synthesis?speaker=#{speaker_id}",
        audio_query.to_json
      )

      # レスポンスをファイルに保存
      File.write(output_file, response.body)
      puts "音声ファイルを保存しました: #{output_file}"
    end
  end
end