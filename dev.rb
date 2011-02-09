require './watcher_dot_net.rb'

def run
  puts `rspec spec`
end

watch ('.*.rb$') { run }
