require 'fileutils'
require 'tempfile'

def rcaml filename, output=nil
  if output.nil?
    output = filename
  end
  file = File.open(filename, "r+")
  t_file = Tempfile.new(filename + ".tmp")
  var = nil
  in_match = false
  rest = false
  file.each_line do |line|
    line =~ /match (\w*) with/
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
        if in_match
          t_file.puts "end"
        end
        t_file.puts "if #{var}.is_a?(Array) && #{var}.empty?"
        t_file.puts "return #{ret}"
        in_match = true
      end
      if count > 0
        if in_match
          t_file.puts "end"
        end
        t_file.print "if #{var}.is_a?(Array)"
        if rest
          t_file.puts " && #{var}.length >= #{count}"
        else
          t_file.puts " && #{var}.length == #{count}"
        end
        t_file.puts locals
        t_file.puts "return #{ret}"
        in_match = true
      end
    else
      in_match = false
      t_file.puts line
    end
  end
  file.close
  t_file.close
  FileUtils.mv(t_file.path, output)
  system "ruby beautiful_ruby.rb #{output}"
end
