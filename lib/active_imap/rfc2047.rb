# An implementation of RFC 2047 decoding.
#
# This file was inspired by the one from sup, which is
# Copyright (c) Sam Roberts <sroberts / uniserve.com> 2004	
# http://gitorious.org/sup/mainline/blobs/master/lib/sup/rfc2047.rb
#
# This file is distributed under the same terms as Ruby.
module ActiveImap
  module Rfc2047
    require 'iconv'

    WORD = %r{=\?([!\#$%&'*+-/0-9A-Z\\^\`a-z{|}~]+)\?([BbQq])\?([!->@-~]+)\?=} # :nodoc: 
    WORDSEQ = %r{(#{WORD.source})\s+(?=#{WORD.source})} # :nodoc: 

    class << self
      # Decodes a string, +from+, containing RFC 2047 encoded words into a target
      # character set, +target+. See iconv_open(3) for information on the
      # supported target encodings. If one of the encoded words cannot be
      # converted to the target encoding, it is left in its encoded form.
      def decode(from, target = 'UTF8')
        if from.blank?
          return ''
        end
        
        from = from.gsub(WORDSEQ, '\1')
        out = from.gsub(WORD) do |word|
          charset, encoding, text = $1, $2, $3

          # B64 or QP decode, as necessary:
          case encoding
          when 'b', 'B'
            #puts text
            text = text.unpack('m*')[0]
            #puts text.dump
          when 'q', 'Q'
            # RFC 2047 has a variant of quoted printable where a ' ' character
            # can be represented as an '_', rather than =32, so convert
            # any of these that we find before doing the QP decoding.
            text = text.tr("_", " ")
            text = text.unpack('M*')[0]
            # Don't need an else, because no other values can be matched in a
            # WORD.
          end

          #text
          Iconv.iconv(target, charset, text)
        end
      end
    end
  end
end