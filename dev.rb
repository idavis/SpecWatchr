require './watcher_dot_net.rb'

def run

  growl_path = 'C:\program files (x86)\Growl for Windows\growlnotify.exe'

  text = `rspec spec --fail-fast`

  text.gsub!('"', "'")

  text = text + "\n\n---"

  opts = ["\"#{growl_path}\"", "\"#{text}\"", "/t:\"output\""]

  `#{opts.join ' '}`

  puts text
end

watch ('.*.rb$') { run }
