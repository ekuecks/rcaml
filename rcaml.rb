require 'fileutils'
require 'tempfile'

module RCaml
  def self.rcaml_to_ruby filename, output=nil
    if output.nil?
      output = filename
    end
    file = File.open(filename, "r+")
    t_file = Tempfile.new(filename + ".tmp")
    var = nil
    @@in_match = false
    @@nested = 0
    file.each_line do |line|
      line =~ /match (\w*) with/
      rest = false
      if $1
        var = $1
        next
      end
      line =~ /(.*)->(.*)/
      if $1 && $2
        cond = $1.delete(" ")
        ret = $2
        locals = ""
        if cond == "[]"
          empty = true
        end
        count = 0
        while cond =~ /\[(\w+),?.*\]/ do
          local = $1
          locals += "#{local} = #{var}[#{count}]\n"
          count += 1

          index = cond.index "[#{local},"
          cond = cond[0..index] + cond[(index + local.length + 2)..-1] if index

          index = cond.index "[#{local}]"
          cond = cond[0..index] + cond[(index + local.length + 1)..-1] if index
        end
        cond =~ /\[\]\+(\w+)/
        if $1
          rest = true
          locals += "#{$1} = #{var}[#{count}..-1]\n"
          count += 1
        end

        if empty
          print_array_case t_file, var, 0, locals, ret, rest
          next
        elsif count > 0
          print_array_case t_file, var, count, locals, ret, rest
        end
      else
        @@in_match = false
        t_file.puts line
      end
    end
    file.close
    t_file.close
    FileUtils.mv(t_file.path, output)
    system "ruby beautiful_ruby.rb #{output}"
  end

  def self.ocaml_to_ruby(filename, output=nil)
    if output == nil
      output = filename.gsub(/\.ml$/, ".rb")
    end
    file = File.open(filename, "r+")
    t_file = Tempfile.new(output + ".tmp")
    # let rec func params -> def func params
    var = nil
    @@in_match = false
    @@nested = 0
    file.each_line do |line|
      locals = ""
      ret = ""
      count = 0
      rest = false
      if line =~ /let[ ]+rec[ ]+(\w+)[ ]+(\w[\w ]+) =/
        name = $1
        params = $2.gsub(/[ ]+$/, "").gsub(" ", ", ")
        t_file.puts "def #{name}(#{params})"
        @@nested += 1
        next
      elsif line =~ /match[ ]+(\w+)[ ]+with/
        var = $1
        next
      elsif line =~ /^\s*\|?\s*\[\]\s*->(.*)/
        ret = $1
        print_array_case t_file, var, 0, locals, ret, rest
        next
      elsif line =~ /^\s*\|?\s*([^\[\]\s:]+)\s*->\s*(.*)/
        bind = $1
        ret = $2
        locals += "#{bind} = #{var}\n"
        print_array_case t_file, var, nil, locals, ret, rest
        next
      elsif line =~ /^\s*\|?\s*\[\s*([^\[\]\s]+)\s*\]\s*->\s*(.*)/
        bind = $1
        ret = $2
        count = 1
        locals += "#{bind} = #{var}[0]\n"
      elsif line.gsub(/^\s*\|/, '') =~ /\s*(.*)->\s*(.*)/
        pattern = $1
        ret = $2
        while pattern =~ /([^:]*)::(.*)/ do
          # cons
          bind = $1
          pattern = $2
          locals += "#{bind} = #{var}[#{count}]\n"
          count += 1
        end
        if pattern =~ /([^ ]*)/
          rest = true
          bind = $1
          locals += "#{bind} = #{var}[#{count}..-1]\n"
          count += 1
        end
      end
      if count > 0
        print_array_case t_file, var, count, locals, ret, rest
      else
        t_file.puts line
      end
    end
    @@nested.times do
      t_file.puts "end"
    end
    file.close
    t_file.close
    FileUtils.mv(t_file.path, output)
    system "ruby beautiful_ruby.rb #{output}"
  end

  private
  def self.print_array_case(t_file, var, count, locals, ret, rest)
    ret.gsub!(/^\s*/, "")
    if @@in_match
      t_file.print "els"
    else
      @@nested += 1
      @@in_match = true
    end
    t_file.print "if #{var}.is_a?(Array)"
    if rest
      t_file.puts " && #{var}.length >= #{count}"
    elsif count
      t_file.puts " && #{var}.length == #{count}"
    else
      t_file.print "\n"
    end
    t_file.print locals unless locals.empty?
    t_file.puts "return #{ret}"
  end
end
