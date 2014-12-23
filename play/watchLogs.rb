require 'fssm'
load("./gokoPlayer.rb")

LOGDIR = '/Users/oda/Library/Application Support/Google/Chrome/Default/File System/006/t/07'
BUYFEATURE_DIR = "gainFeature.txt"
PLAYFEATURE_DIR = "playFeature.txt"
ACTIONFEATURE_DIR = "actionFeature.txt"

$drawFileName = nil
$logFileName = nil
$logFileName = nil

Thread.abort_on_exception = true

t = Thread.new{
  while true
    sleep 0.5
    if($logFileName == nil || $drawFileName == nil)
      next
    end
    s = File.stat($logFileName)
    if(@finalTimeStamp == nil || (Time.now - s.mtime  > 1) && (@finalTimeStamp != s.mtime && true))
      @finalTimeStamp = s.mtime
      File.open(BUYFEATURE_DIR, 'w'){|out|
        File.open(PLAYFEATURE_DIR, 'w'){|outAction|
          File.open(ACTIONFEATURE_DIR, 'w'){|outAction2|

            #これしないと変更が反映されない
            out.sync = true
            outAction.sync = true
            outAction2.sync = true

            parser = GokoPlayer.new
            File.open($logFileName, 'r') {|file|
              File.open($drawFileName, 'r') {|drawfile|
                parser.parse(file, out, outAction, outAction2, drawfile, true, "")
              }
            }
          }
        }
      }
    end
  end

}

FSSM.monitor(LOGDIR ,'**/*') do

  create do |base,file|
    puts "create"
    if($logFileName == nil)
      $logFileName = base + "/" + file
    else
      $drawFileName = base + "/" + file
    end
  end
  delete do |base,file|
    $drawFileName = nil
    $logFileName = nil
  end

end