# rcaml
##Usage
###rcaml_file.rb
```ruby
def sum lst
  match lst with
    [] -> 0
    [first] -> first
    [fist] + rest -> first + sum rest
  end
end
```

###ocaml_file.ml
```ocaml
let rec sum lst =
  match lst with
  | [] -> 0
  | [first] -> first
  | first::rest -> first + sum rest
```

###rcaml_to_ruby
Takes an 'rcaml' file and converts it to valid ruby
Parameters: input_file, output_file=nil
If you do not specify an output file, then it will overwrite the input file
```ruby
RCaml::rcaml_to_ruby "rcaml_file.rb", "output.rb"
```
###output.rb
```ruby
def sum lst
  if lst.is_a?(Array) && lst.length == 0
    return 0
  elsif
    lst.is_a?(Array) && lst.length == 1
    first = lst[0]
    return first
  elsif lst.is_a?(Array) && lst.length >= 1
    first = lst[0]
    rest = lst[1..-1]
    return first + sum rest
  end
end
```

###ocaml_to_ruby
Takes an ocaml file and converts it to valid ruby
Parameters: input_file, output_file=nil
If you do not specify an output file, then it will make a new ruby file with the same name as the input file but a .rb extension instead of .ml
```ruby
RCaml::ocaml_to_ruby "ocaml_file.ml", "output.rb"
```
###output.rb
```ruby
def sum lst
  if lst.is_a?(Array) && lst.length == 0
    return 0
  elsif
    lst.is_a?(Array) && lst.length == 1
    first = lst[0]
    return first
  elsif lst.is_a?(Array) && lst.length >= 1
    first = lst[0]
    rest = lst[1..-1]
    return first + sum rest
  end
end
```
