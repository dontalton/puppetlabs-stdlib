
Puppet::Type.type(:file_line).provide(:ruby) do

  def exists?
    lines.find do |line|
      line.chomp == resource[:line].chomp
    end
  end

  def create
    if resource[:match]
      handle_create_with_match()
    else
      handle_create_without_match()
    end
  end

  def destroy
    local_lines = lines
    File.open(resource[:path],'w') do |fh|
      fh.write(local_lines.reject{|l| l.chomp == resource[:line] }.join(''))
    end
  end

  private
  def lines
    # If this type is ever used with very large files, we should
    #  write this in a different way, using a temp
    #  file; for now assuming that this type is only used on
    #  small-ish config files that can fit into memory without
    #  too much trouble.
    @lines ||= File.readlines(resource[:path])
  end

  def handle_create_with_match()
    regex = resource[:match] ? Regexp.new(resource[:match]) : nil
    match_count = lines.select { |l| regex.match(l) }.size
    if match_count > 1
      raise Puppet::Error, "More than one line in file '#{resource[:path]}' matches pattern '#{resource[:match]}'"
    end
    if [:match_location]
      # find what line has the text and match it up to match_location
      # if they are out of sync, delete it from the lines list, then re-add it
      # at the specified location
      if (match_count == 0)
        line_counter = 0
        File.open(resource[:path], 'w') do |fh|
          lines.each do |l|
            if line_counter == [:match_location]
              fh.puts([:line])
              fh.puts(l)
            else
              fh.puts(l)
            end
            line_counter += 1 
          end
        end
      end 
    else
      File.open(resource[:path], 'w') do |fh|
        lines.each do |l|
          fh.puts(regex.match(l) ? resource[:line] : l)
        end

        if (match_count == 0)
          fh.puts(resource[:line])
        end
      end
    end
  end

  def handle_create_without_match
    line_counter = 0
    File.open(resource[:path], 'w') do |fh|
      lines.each do |l|
        if line_counter == [:match_location]
          fh.puts([:line])
          fh.puts(l)
        else
          fh.puts(l)
        end
        line_counter += 1
      end
    end
  end


end
