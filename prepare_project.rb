def create_database_yml
  yml_file_generator = DatabaseYMLGenerator.new
  yml_file_generator.create_file
end

def add_12_factor
  if File.exist?("Gemfile")
    File.open("Gemfile", "a") { |file| file.puts "gem 'rails_12factor', group: :production"} unless File.readlines("Gemfile").grep(/rails_12factor/).any?
    File.open("Gemfile", "a") { |file| file.puts "gem 'foreman'"} unless File.readlines("Gemfile").grep(/foreman/).any?
  end
end

class DatabaseYMLGenerator
  require 'cgi'
  require 'uri'
  require 'yaml'

  def initialize
    begin
      @uri = URI.parse(ENV["DATABASE_URL"])
    rescue URI::InvalidURIError
      @uri = URI.parse("postgres://root:root@localhost/code_fresh_db")
    end

    extract_fields_from_uri
  end

  def create_file
    @yaml_string = File.exist?("config/database.yml") ? get_altered_file : get_new_file
    File.open("config/database.yml", "w") do |file|
      file.puts @yaml_string
    end
  end

  private
  def extract_fields_from_uri
    @adapter  = @uri.scheme == "postgres" ? "postgresql" : @uri.scheme
    @database = (@uri.path || "").split("/")[1]
    @username = @uri.user
    @password = @uri.password
    @host     = @uri.host
    @port     = @uri.port
    @params   = CGI.parse(@uri.query || "")
  end

  def get_altered_file
    databases_file = YAML.load_file "config/database.yml"

    set_pass_and_user(databases_file)
    database_yml_by_uri(databases_file , 'production')
    database_yml_by_uri(databases_file , 'development')

    YAML.dump(databases_file).to_s
  end

  def get_new_file
    "production:
  #{attribute_yml "adapter", @adapter}
    #{attribute_yml "database", @database}
    #{attribute_yml "username", @username}
    #{attribute_yml "password", @password, true if @password}
    #{attribute_yml "host", @host}
    #{attribute_yml "port", @port}
development:
  #{attribute_yml "adapter", @adapter}
    #{attribute_yml "database", @database}
    #{attribute_yml "username", @username}
    #{attribute_yml "password", @password, true if @password}
    #{attribute_yml "host", @host}
    #{attribute_yml "port", @port}
test:
  adapter: postgresql
  encoding: utf8
  database: code_fresh_test
  pool: 5
  username: root
  password: root
  min_messages: warning
#{params_yml}
    "
  end

  def database_yml_by_uri(databases_conn , env)
    set_yml_attr(databases_conn , env , "adapter" , attribute_str(@adapter))
    set_yml_attr(databases_conn , env , "database" , attribute_str(@database))
    set_yml_attr(databases_conn , env , "username" , attribute_str(@username))
    set_yml_attr(databases_conn , env , "password" , attribute_str(@password))
    set_yml_attr(databases_conn , env , "host" , attribute_str(@host))
    set_yml_attr(databases_conn , env , "port" , attribute_str(@port))
  end

  def set_yml_attr(databases_conn , env , name , value)
    databases_conn[env][name] = attribute_str value
  end

  def force_needed?(name)
    if name == 'password'
      !(@password.include?('\'') || @password.include?('"'))
    else
      false
    end
  end

  def set_pass_and_user(databases_conn)
    databases_conn.each do |databse_conn|
      databse_conn[1]["username"] = attribute_str 'root'
      databse_conn[1]["password"] = attribute_str 'root'
    end
  end

  def attribute_str value, force_string = false
    if value
      force_string ? '"' + value + '"' : value
    else
      ''
    end
  end

  def params_yml
    param_yml = '' ; @params.each {|key, value| param_yml += "#{key} : #{value.first} \n" } ; param_yml
  end

  def attribute_yml name, value, force_string = false
    value ? "#{name}: #{attribute_str(value , force_string)}" : ""
  end

end

add_12_factor
create_database_yml