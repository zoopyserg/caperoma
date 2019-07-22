# frozen_string_literal: true

class Caperoma
  module Version
    MAJOR, MINOR, PATCH = File.read(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')).split('.')

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
end
