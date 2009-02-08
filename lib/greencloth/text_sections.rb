module GreenClothTextSections

  def extract_section_title(section_text)
    if /(^h[123]\.)(.*?$)(.*)/m =~ section_text
      # h1. style section
      title = $~[2]
    else
      title = section_text.split("\n").first.to_s
    end
  end

  def add_wiki_section_divs(input)
    html_sections = input.index_split(/<\s*h[123]/)

    start_div = "<div class=\"wiki_section\" id=\"wiki_section-%d\">\n"
    end_div = "\n</div>\n"

    section_index = 0
    output = ""

    html_sections.each do |section|
      output << start_div % section_index

      # indent lines
      lines = section.split("\n")
      lines.each {|l| output << "  " + l + "\n"}

      output << end_div
      section_index += 1
    end

    # strip the trailing newline from the last closing div
    output.chomp! if section_index > 0
    return output
  end

  # get all sections in an array
  def sections
    section_start_re = Regexp.union(GreenCloth::TEXTILE_HEADING_RE, GreenCloth::HEADINGS_RE)
    # get the sections
    return self.index_split(section_start_re)
  end

  module ClassMethods
    # returns true if +section+ starts with a section heading markup
    def is_heading_section?(section)
      section_start_re = Regexp.union(GreenCloth::TEXTILE_HEADING_RE, GreenCloth::HEADINGS_RE)
      return (section_start_re =~ section) == 0
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
  end
end
