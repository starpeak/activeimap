#--
# Copyright (c) 2010 Sven G. Broenstrup
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module ActiveImap
  require 'net/imap'
  require 'active_support'
  require 'active_model'
  
  extend ActiveSupport::Autoload
  
  autoload :Config
  autoload :Connection
  autoload :Rfc2047
  autoload :Folder
  autoload :Message
  autoload :Actor
  
  class << self  
    
    def config
      @config ||= ActiveImap::Config.new
    end
    
    def configure(&block)
      config.configure(&block)
    end
  end
end

require 'active_support/i18n'
I18n.load_path << File.dirname(__FILE__) + '/active_imap/locale/en.yml'