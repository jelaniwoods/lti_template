namespace :lti do
  desc "generate scaffolds for basic LTI app"
  # Make all migrations
  # Modify migration files to set default values
  #   How to do that? Can I just look for files with names: that end in `_create_xxx.rb`?
  #   Then in the file, gsub `column_name` with `column_name, default: true` for enabled in Credential
  #   For Submission: :score, default: 0.0
  #   For payload: `t.jsonb :payload, null: false, default: {}`
  # Run migrations
  #    "rails db:migrate"
  # Modify model files with associations helpers, etc
  #
  #   models/administrator.rb
  #     has_many :credentials, dependent: :destroy
  #   models/credential.rb
  #     belongs_to :administrator
  #     has_many :consumptions, dependent: :destroy
  #     has_many :tool_consumers, through:   :consumptions, source:   :tool_consumer
  #     has_many :launches, through:   :tool_consumers, source:   :launch
  #
  #     has_secure_token :consumer_key
  #     has_secure_token :consumer_secret
  #   models/tool_consumer.rb
  #     has_one :launch, dependent: :destroy
  #     has_many :consumptions, dependent: :destroy
  #     has_many :credentials, through: :consumptions, source: :credential
  #   models/consumption.rb
  #     belongs_to :credential
  #     belongs_to :tool_consumer
  #   models/launch.rb
  #     belongs_to :context
  #     belongs_to :resource
  #     belongs_to :enrollment
  #     belongs_to :tool_consumer
  #     belongs_to :user
  #     has_one :credential, through: :tool_consumer, source: :credentials
  #   models/enrollment.rb
  #     belongs_to :context
  #     has_one :launch, dependent: :destroy
  #     has_many :submissions, dependent: :destroy
  #     belongs_to :user
  #   models/resource.rb
  #     belongs_to :context
  #     has_one :launch, dependent: :destroy
  #     has_many :submissions, dependent: :destroy
  #   models/context.rb
  #     has_many :launches, dependent: :destroy
  #     has_many :enrollments, dependent: :destroy
  #     has_many :resources, dependent: :destroy
  #   models/submission.rb
  #     belongs_to :resource
  #     belongs_to :enrollment
  #   models/user.rb
  #     has_many :enrollments, dependent: :destroy
  #     has_many :launches, dependent: :destroy
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
    # Either make own generator that doesn't use `link_to_back_or_show` or add that to application_helper
    # Currently, the template adds the helper to the project

     system! "rails generate draft:devise administrator"
     system! "rails generate draft:scaffold credential consumer_key:string consumer_secret:string administrator_id:integer enabled:boolean"
     system! "rails generate draft:scaffold tool_consumer instance_guid:string instance_name:string instance_description:string instance_url:string instance_contact_email:string"
     system! "rails generate draft:scaffold consumption tool_consumer_id:integer credential_id:integer"
     system! "rails generate draft:scaffold launch context_id:integer tool_consumer_id:integer user_id:integer enrollment_id:integer resource_id:integer payload:jsonb"
     system! "rails generate draft:scaffold enrollment context_id:integer user_id:integer roles:string"
     system! "rails generate draft:scaffold resource id_from_tc:string context_id:integer title:string"
     system! "rails generate draft:resource context title:string id_from_tc:string"
     system! "rails generate draft:scaffold submission enrollment_id:integer resource_id:integer score:float"
     system! "rails generate draft:scaffold user first_name:string last_name:string preferred_name:string id_from_tc:string"

    migration_files = Dir["db/migrate/*"].select { |x| x =~ /_create_[\w*]*.rb/ }

    model_names = []
    migration_files.each do |file|
      name = file.split("_").last.split(".").first.singularize
      model_names << name
      # p name

      # case name
      # when "credential"
      #   IO.write(file, File.open(file) do |f|
      #     f.read.gsub(/:enabled/, ":enabled, default: true")
      #   end
      #   )
      # when "submission"
      #   IO.write(file, File.open(file) do |f|
      #     f.read.gsub(/:score/, ":score, default: 0.0")
      #   end
      #   )
      # when "launch"
      #   IO.write(file, File.open(file) do |f|
      #     f.read.gsub(/:payload/, ":payload, null: false, default: {}")
      #   end
      #   )
      #   puts open(file).read
      # end
    end
    model_files = model_names.map { |name| "app/models/" + name + ".rb" }
    p model_files

    model_files.each_with_index do |file, i|
      p model_names[i]
      case model_names[i]

      when "launch"
        content = "class Launch < ApplicationRecord\n  " +
          "belongs_to :context\n  " +
          "belongs_to :resource\n  " +
          "belongs_to :enrollment\n  " +
          "belongs_to :tool_consumer\n  " +
          "belongs_to :user\n  " +
          "has_one :credential, through: :tool_consumer, source: :credentials\n" +
          "end\n"
        write_to_file(content, file)

      when "administrator"
        content = "class Administrator < ApplicationRecord\n  " +
          "# Include default devise modules. Others available are:\n  " + 
          "# \t:confirmable, :lockable, :timeoutable, :trackable and :omniauthable\n  "
          "devise :database_authenticatable, :registerable,\n\t\t" +
          ":recoverable, :rememberable, :validatable\n  " +
          "has_many :credentials, dependent: :destroy\n" +
          "end\n"
        write_to_file(content, file)

      when "consumption"
        content = "class Consumption < ApplicationRecord\n  " +
          "belongs_to :credential\n  " +
          "belongs_to :tool_consumer\n" +
          "end\n"
        write_to_file(content, file)

      when "tool_consumer"
        content = "class Consumption < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :consumptions, dependent: :destroy\n  " +
          "has_many :credentials, through: :consumptions, source: :credential\n" +
          "end\n"
        write_to_file(content, file)

      when "credential"
        content = "class Credential < ApplicationRecord\n  " +

          "belongs_to :administrator\n  " +
          "has_many :consumptions, dependent: :destroy\n  " +
          "has_many :tool_consumers, through:   :consumptions, source:   :tool_consumer\n  " +
          "has_many :launches, through:   :tool_consumers, source:   :launch\n\n  " +
      
          "has_secure_token :consumer_key\n  " +
          "has_secure_token :consumer_secret\n" +
          "end\n"
        write_to_file(content, file)

      when "enrollment"
        content = "class Enrollment < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :submissions, dependent: :destroy\n  " +
          "belongs_to :context\n  " +
          "belongs_to :user\n" +
          "end\n"
        write_to_file(content, file)
      when "resource"
        content = "class Resource < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :submissions, dependent: :destroy\n  " +
          "belongs_to :context\n" + 
          "end\n"
        write_to_file(content, file)
      when "context"
        content = "class Context < ApplicationRecord\n  " +
          "has_one :launch, dependent: :destroy\n  " +
          "has_many :launches, dependent: :destroy\n  " +
          "has_many :enrollments, dependent: :destroy\n  " +
          "has_many :resources, dependent: :destroy\n" +
          "end\n"
        write_to_file(content, file)
      when "submission"
        content = "class Submission < ApplicationRecord\n  " +
          "belongs_to :resource\n  " +
          "belongs_to :enrollment\n  " +
          "end\n"
        write_to_file(content, file)

      when "user"
        content = "class User < ApplicationRecord\n  " +
          "has_many :enrollments, dependent: :destroy\n  " +
          "has_many :launches, dependent: :destroy\n  " +
          "end\n"
        write_to_file(content, file)
      end

      # migrate?
      # Modify routes to have the config url
      # modify some controller with the action to render the conig path
      # Make a generator for this
      system! "rails db:migrate"

    end


  end

end
