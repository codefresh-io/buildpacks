def attribute_str value, force_string = false
  if value
    force_string ? '"' + value + '"' : value
  else
    ''
  end
end

def attribute_yml name, value, force_string = false
  value ? "#{name}: #{attribute_str(value , force_string)}" : ""
end

def create_database_yml
  require 'cgi'
  require 'uri'
  require 'yaml'

  begin
    uri = URI.parse(ENV["DATABASE_URL"])
  rescue URI::InvalidURIError
    uri = URI.parse("postgres://root:root@localhost/code_fresh_prod")
  end

  adapter  = uri.scheme
  adapter  = "postgresql" if adapter == "postgres"
  database = (uri.path || "").split("/")[1]
  username = uri.user
  password = uri.password
  host     = uri.host
  port     = uri.port
  params   = CGI.parse(uri.query || "")

  if File("config/database.yml").exist?
    databases_conn = YAML.load_file "config/database.yml"
    databases_conn.each do |databse_conn|
      databse_conn[1]["username"] = attribute_str 'root'
      databse_conn[1]["password"] = attribute_str 'root'
    end

    databases_conn["production"]["adapter"] = attribute_str  adapter
    databases_conn["production"]["database"] = attribute_str  database
    databases_conn["production"]["username"] = attribute_str  username
    databases_conn["production"]["password"] = attribute_str  password, true if password
    databases_conn["production"]["host"] = attribute_str  host
    databases_conn["production"]["port"] = attribute_str  port
    File.open("config/database.yml", 'w') { |f| YAML.dump(databases_conn, f) }
  else
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
end

def add_12_factor
  File.open("Gemfile", "a") do |file|
    file.puts "gem 'rails_12factor', group: :production"
    file.puts "gem 'foreman'"
  end
end

add_12_factor
create_database_yml
