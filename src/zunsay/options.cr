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
  end
end
