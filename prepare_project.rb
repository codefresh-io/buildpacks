def attribute_yml value, force_string = false
  if value
    force_string ? '"' + value + '"' : value
  else
    ''
  end
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


  databases_conn = YAML.load_file "config/database.yml"
  databases_conn.each do |databse_conn|
    databse_conn[1]["username"] = attribute_yml 'root'
    databse_conn[1]["password"] = attribute_yml 'root'
  end

  databases_conn["production"]["adapter"] = attribute_yml  adapter
  databases_conn["production"]["database"] = attribute_yml  database
  databases_conn["production"]["username"] = attribute_yml  username
  databases_conn["production"]["password"] = attribute_yml  password, true if password
  databases_conn["production"]["host"] = attribute_yml  host
  databases_conn["production"]["port"] = attribute_yml  port
  File.open("config/database.yml", 'w') { |f| YAML.dump(databases_conn, f) }
end

def add_12_factor
  File.open("Gemfile", "a") do |file|
    file.puts "gem 'rails_12factor', group: :production"
    file.puts "gem 'foreman'"
  end
end

add_12_factor
create_database_yml
