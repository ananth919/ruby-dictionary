# encoding: utf-8

require 'zlib'
require 'ruby-dictionary/word_path'

class Dictionary
  def initialize(word_list)
    @word_path = parse_words(word_list)
  end

  def exists?(word)
    path = word_path(word)
    !!(path && path.leaf?)
  end

  def starting_with(prefix)
    prefix = prefix.to_s.strip.downcase
    path = word_path(prefix)
    return [] if path.nil?

    words = [].tap do |words|
      words << prefix if path.leaf?
      words.concat(path.suffixes.collect! { |suffix| "#{prefix}#{suffix}" })
    end

    words.sort!
  end

  def hash
    self.class.hash ^ @word_path.hash
  end

  def ==(obj)
    obj.class == self.class && obj.hash == self.hash
  end

  def inspect
    "#<#{self.class.name}>"
  end

  def to_s
    inspect
  end

  def self.from_file(path, separator = "\n")
    contents = case path
                 when String then File.read(path)
                 when File then path.read
                 else raise ArgumentError, "path must be a String or File"
               end

    if contents.start_with?("\x1F\x8B")
      gz = Zlib::GzipReader.new(StringIO.new(contents))
      contents = gz.read
    end

    new(contents.split(separator))
  end

  private

  def parse_words(word_list)
    raise ArgumentError, "word_list should be an array of strings" unless word_list.kind_of?(Array)

    WordPath.new.tap do |word_path|
      word_list.each { |word| word_path << word.to_s }
    end
  end

  def word_path(str)
    @word_path.find(str)
  end
end
