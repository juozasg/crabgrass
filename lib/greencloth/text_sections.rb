module GreenClothTextSections
  # %r{
  #     ^h[123]\.                   # beginning of the section heading like 'h1.'
  #     .*?                         # section contents
  #     (?=\Z|(^[h][123]\.))        # lookahead matches for next section heading or end of string
  #   }xm
  
  # insert [Edit] links for every section
  def edit_section_links(text)
    section_start_re = Regexp.union(/^h[123]\./, GreenCloth::HEADINGS_RE)
        
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
        section = " " + section
        
        if section =~ GreenCloth::HEADINGS_RE
          title = section.split(/\r?\n/).first
          # there must be a space between section title and edit link markup
        end
        text << edit_section_link_markup(title, i) + section
      end
    end
  end

  def edit_section_link_markup(title, index)
    if @edit_section_link_block
      link = @edit_section_link_block.call(title.to_s, index)
    else
      link = "/edit?section=#{index}"
    end
    
    "%(editsection)!images/actions/pencil.png!:[edit section -> #{link}]%"
  end
end