def add_12_factor
  if File.exist?("Gemfile")
    File.open("Gemfile", "a") { |file| file.puts "gem 'rails_12factor', group: :production"} unless File.readlines("Gemfile").grep(/rails_12factor/).any?
    File.open("Gemfile", "a") { |file| file.puts "gem 'foreman'"} unless File.readlines("Gemfile").grep(/foreman/).any?
  end
end

add_12_factor