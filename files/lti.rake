namespace :lti do
  desc "Generates neccessary resources for basic LTI app, modifies migration files with default values, adds association helper methods"
  # Make all migrations
  # Modify migration files to set default values
  #   How to do that? Can I just look for files with names: that end in `_create_xxx.rb`?
  #   Then in the file, gsub `column_name` with `column_name, default: true` for enabled in Credential
  #   For Submission: :score, default: 0.0
  #   For payload: `t.jsonb :payload, null: false, default: {}`
  # Modify model files with associations helpers, etc
  # Adds Launch service
  # Add seed data
 
  task setup: :environment do
    require "fileutils"
    include FileUtils
    def system!(*args)
      system(*args) || abort("\n== Command #{args} failed ==")
    end

    def write_to_file(content, file)
      IO.write(file, File.open(file) do |f|
                       f.read.gsub(/^.*/m, content)
                     end)
    end
    
    # Currently, the template adds the link_back_or_show helper to the project

     system! "rails generate draft:devise administrator"
     system! "rails generate draft:lti credential consumer_key:string consumer_secret:string administrator_id:integer enabled:boolean"
     system! "rails generate draft:lti tool_consumer instance_guid:string instance_name:string instance_description:string instance_url:string instance_contact_email:string"
     system! "rails generate draft:lti consumption tool_consumer_id:integer credential_id:integer"
     system! "rails generate draft:lti enrollment context_id:integer user_id:integer roles:string"
     system! "rails generate draft:lti resource id_from_tc:string context_id:integer title:string"
     system! "rails generate draft:lti context title:string id_from_tc:string"
     system! "rails generate draft:lti submission enrollment_id:integer resource_id:integer score:float"
     system! "rails generate draft:lti user first_name:string last_name:string preferred_name:string id_from_tc:string"
     system! "rails generate draft:launch"

    migration_files = Dir["db/migrate/*"].select { |x| x =~ /_create_[\w*]*.rb/ }

    model_names = []
    migration_files.each do |file|
      name = file.split("_").last.split(".").first.singularize
      if name == "consumer"
        name = "tool_consumer"
      end
      model_names << name
      case name
      when "credential"
        IO.write(file, File.open(file) do |f|
          f.read.gsub(/:enabled/, ":enabled, default: true")
        end
        )
      when "submission"
        IO.write(file, File.open(file) do |f|
          f.read.gsub(/:score/, ":score, default: 0.0")
        end
        )
      when "launch"
        IO.write(file, File.open(file) do |f|
          f.read.gsub(/:payload/, ":payload, null: false, default: {}")
        end
        )
      end
    end
    model_files = model_names.map { |name| "app/models/" + name + ".rb" }

    model_files.each_with_index do |file, i|
      p model_names[i]
      case model_names[i]

      when "launch"
        content = "class Launch < ApplicationRecord\n  " +
          "belongs_to :context\n  " +
          "belongs_to :resource\n  " +
          "belongs_to :enrollment\n  " +
          "belongs_to :tool_consumer\n  " +
          "belongs_to :user\n\n  " +
          "has_one :credential, through: :tool_consumer, source: :credentials\n\n" +
          "end\n"
        write_to_file(content, file)

      when "tool_consumer"
        content = "class ToolConsumer < ApplicationRecord\n  " +
        "has_one :launch, dependent: :destroy\n  " +
        "has_many :consumptions, dependent: :destroy\n  " +
        "has_many :credentials, through: :consumptions\n\n  " +
        "validates :instance_guid, presence: true, uniqueness: true\n\n" +
        "end\n"
        write_to_file(content, file)

      when "administrator"
        content = "class Administrator < ApplicationRecord\n  " +
          "# Include default devise modules. Others available are:\n  " + 
          "#   :confirmable, :lockable, :timeoutable, :trackable and :omniauthable\n  " +
          "devise :database_authenticatable, :registerable,\n    " +
          ":recoverable, :rememberable, :validatable\n  " +
          "has_many :credentials, dependent: :destroy\n\n" +
          "end\n"

        write_to_file(content, file)

      when "consumption"
        content = "class Consumption < ApplicationRecord\n  " +
          "belongs_to :credential\n  " +
          "belongs_to :tool_consumer\n\n" +
          "end\n"
        write_to_file(content, file)

      when "tool_consumer"
        content = "class Consumption < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :consumptions, dependent: :destroy\n  " +
          "has_many :credentials, through: :consumptions, source: :credential\n\n" +
          "end\n"
        write_to_file(content, file)

      when "credential"
        content = "class Credential < ApplicationRecord\n  " +

          "belongs_to :administrator\n  " +
          "has_many :consumptions, dependent: :destroy\n  " +
          "has_many :tool_consumers, through: :consumptions, source: :tool_consumer\n  " +
          "has_many :launches, through: :tool_consumers, source: :launch\n\n  " +
      
          "has_secure_token :consumer_key\n  " +
          "has_secure_token :consumer_secret\n\n  " +
          "def create_tool_provider(params = {})\n  " +
          "  IMS::LTI::ToolProvider.new(consumer_key, consumer_secret, params)\n  " +
          "end\n\n" +
          "end\n"
        write_to_file(content, file)

      when "enrollment"
        content = "class Enrollment < ApplicationRecord\n  " +
          "has_many :launches, dependent: :destroy\n  " +
          "has_many :submissions, dependent: :destroy\n  " +
          "belongs_to :context\n  " +
          "belongs_to :user\n\n" +
          "end\n"
        write_to_file(content, file)
      when "resource"
        content = "class Resource < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :submissions, dependent: :destroy\n  " +
          "belongs_to :context\n\n" + 
          "end\n"
        write_to_file(content, file)
      when "context"
        content = "class Context < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :launches, dependent: :destroy\n  " +
          "has_many :enrollments, dependent: :destroy\n  " +
          "has_many :resources, dependent: :destroy\n\n" +
          "end\n"
        write_to_file(content, file)
      when "submission"
        content = "class Submission < ApplicationRecord\n  " +
          "belongs_to :resource\n  " +
          "belongs_to :enrollment\n\n" +
          "end\n"
        write_to_file(content, file)

      when "user"
        content = "class User < ApplicationRecord\n  " +
          "has_many :enrollments, dependent: :destroy\n  " +
          "has_many :launches, dependent: :destroy\n\n" +
          "end\n"
        write_to_file(content, file)
      end

      # migrate?
      # Make a generator for this
      
    end
    
  end

end
