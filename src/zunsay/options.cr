require "./action"
require "./config"

module Zunsay
  class Options
    property action : Action = Action::Synthesis
    property host : String = DEFAULT_HOST
    property port : Int32 = DEFAULT_PORT
    property text : String = ""
    property speaker_id : Int32 = 1
    property output_file : String = "output.wav"

    # 音声合成の詳細設定
    property speed_scale : Float64 = 1.0
    property pitch_scale : Float64 = 0.0
    property intonation_scale : Float64 = 1.0
    property volume_scale : Float64 = 1.0
  end
end
