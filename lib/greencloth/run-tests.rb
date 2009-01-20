#!/usr/bin/env ruby

require File.join(File.expand_path(File.dirname(__FILE__), 'text_sections.rb'))
require File.join(File.expand_path(File.dirname(__FILE__), 'greencloth'))
require File.join(File.expand_path(File.dirname(__FILE__), '../extension/string'))

require 'yaml'

def process_link_data(link_data)
  if link_data[:edit_section]
    return edit_section_link(link_data[:section_title], link_data[:section_index])
  end
end

def edit_section_link(section_title, section_index)
  %Q{<a href="/edit?section=#{section_index}"><img src="http://localhost:3000/images/actions/pencil.png" alt="" />edit section</a>}
end

i = 0
files = ARGV[0] || Dir["tests/*.yml"]
files.each do |testfile|
  YAML::load_documents( File.open( testfile ) ) do |doc|
    next unless doc
    i += 1
    in_markup = doc['in']
    out_markup = doc['out'] || doc['html']
    if in_markup and out_markup
      greencloth = GreenCloth.new( in_markup )
      
      # generate section edit links for section.yml
      if testfile =~ /sections\.yml/
        html = greencloth.to_html {|ld| process_link_data(ld)}
      else
        html = greencloth.to_html
      end
      html.gsub!( /\n+/, "\n" )
      out_markup.gsub!( /\n+/, "\n" )
      if html == out_markup
        putc "."
      else
        puts "\n------- #{testfile} failed -------"
        puts "---- IN ----"; p in_markup
        puts "---- OUT ----"; puts html
        puts "---- EXPECTED ----"; puts out_markup
        puts ""
      end
    end
  end
  puts ""
end

