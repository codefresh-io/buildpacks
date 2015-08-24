def params_yml(params = {})
  param_yml = ''
  params.each do |key, value|
    param_yml += "#{key} : #{value.first} \n"
  end
  param_yml
end

def attribute_yml name, value, force_string = false
  if value
    value_string =
        if force_string
          '"' + value + '"'
        else
          value
        end
    "#{name}: #{value_string}"
  else
    ""
  end
end

def create_database_yml
  require 'cgi'
  require 'uri'

  begin
    uri = URI.parse(ENV["DATABASE_URL"])
  rescue URI::InvalidURIError
    uri = URI.parse("postgres://postgresql@localhost/code_fresh_prod")
  end

  adapter  = uri.scheme
  adapter  = "postgresql" if adapter == "postgres"
  database = (uri.path || "").split("/")[1]
  username = uri.user
  password = uri.password
  host     = uri.host
  port     = uri.port
  params   = CGI.parse(uri.query || "")
  File.open("config/database.yml", "w") do |file|
    file.puts <<-DATABASE_YML
production:
#{attribute_yml "adapter",  adapter}
    #{attribute_yml "database", database}
    #{attribute_yml "username", username}
    #{attribute_yml "password", password, true if password}
    #{attribute_yml "host",     host}
    #{attribute_yml "port",     port}
development:
  adapter: postgresql
  encoding: utf8
  database: code_fresh_develop
  pool: 5
  username: root
  password: root
  min_messages: warning
test:
  adapter: postgresql
  encoding: utf8
  database: code_fresh_test
  pool: 5
  username: root
  password: root
  min_messages: warning
#{params_yml(params)}
    DATABASE_YML
  end
end

def add_12_factor
  unless File.foreach("Gemfile").grep(/rails_12factor/).any?
    File.open("Gemfile", "a") do |file|
      file.puts "gem 'rails_12factor', group: :production"
      file.puts "gem 'foreman'"
    end
  end
end

add_12_factor
create_database_yml
