Bundler.setup
require "test/unit"
require "mocha"
require "shoulda"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "alexa"

class Test::Unit::TestCase
  def fixture_file(filename)
    file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
    File.read(file_path)
  end
end