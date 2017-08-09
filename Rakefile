require 'bundler/gem_tasks'

def load_if_available(req_path)
  require req_path
  yield
rescue LoadError
  false # req not available
end

load_if_available('rspec/core/rake_task') { RSpec::Core::RakeTask.new(:spec) }
load_if_available('rubocop/rake_task') { RuboCop::RakeTask.new(:rubocop) }

task default: %i[rubocop spec]
