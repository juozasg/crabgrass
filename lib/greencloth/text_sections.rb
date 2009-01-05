module GreenClothTextSections
  # %r{
  #     ^h[123]\.                   # beginning of the section heading like 'h1.'
  #     .*?                         # section contents
  #     (?=\Z|(^[h][123]\.))        # lookahead matches for next section heading or end of string
  #   }xm
  
  # insert edit section links for every section
  def edit_section_links(text)
    # don't do anything unless we have a block
    return if @edit_section_link_block.nil?

    section_start_re = Regexp.union(GreenCloth::TEXTILE_HEADING_RE, GreenCloth::HEADINGS_RE)
    # get the sections
    sections = text.index_split(section_start_re)
    
    # no edit section links for a single section
    return if sections.size == 1
    
    text.replace('')
    sections.each_with_index do |section, i|
      if /(^h[123]\.)(.*?$)(.*)/m =~ section
        # h1. style section
        heading = $~[1]
        title = $~[2]
        content = $~[3]
        
        # put section link between h1. and the rest of the section
        text << heading + " " + edit_section_link_markup(title, i) + title + content
      elsif /\A\s*\Z/ =~ section
        # whitespace section
        text << section
      else
        # setext section or no heading section
        title = ""
        # there must be a space between section title and edit link markup
        section = " " + section
        
        if section =~ GreenCloth::HEADINGS_RE
          title = section.split(/\r?\n/).first
        end
        text << edit_section_link_markup(title, i) + section
      end
    end
  end

  # generate 'edit section' link markup for section number +index+
  def edit_section_link_markup(title, index)
    # don't generate any links unless we have a block
    return "" if @edit_section_link_block.nil?

    link = @edit_section_link_block.call(title.to_s, index)
    return "" if link.nil? or link.empty?

    # offtag the link and embed it in a span
    "%(editsection)#{offtag_it(link)}%" 
  end
  
end