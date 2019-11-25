# Helper methods to copy in files
# ===============================

# ENV = :prod
ENV = :dev

def path_to_file(filename)
  if ENV == :prod
    "https://raw.githubusercontent.com/jelaniwoods/good_template/master/files/#{filename}"
  else
    File.join(__dir__, "files", filename)
  end
end

def path_to_blob(filename)
  "https://raw.githubusercontent.com/jelaniwoods/good_template/master/files/#{filename}"
end

def render_file(filename)
  if ENV == :prod
    require "open-uri"

    begin
      open(path_to_file(filename)).read
    rescue StandardError
      open(path_to_blob(filename)).read
    end
  else
    IO.read(path_to_file(filename))
  end
end

# Add standard gems
# =================

gem "ims-lti", "~> 1.2", ">= 1.2.2"

gem_group :development, :test do
  gem "awesome_print"
  gem "dotenv-rails"
  gem "pry-rails"
  gem "rubocop"
  gem "rubocop-performance"
end

gem_group :development do
  gem "annotate"
  gem "better_errors", github: "charliesome/better_errors"
  gem "binding_of_caller"
  gem "draft_generators", github: "jelaniwoods/draft_generators"
  gem "letter_opener"
  gem "rails-erd"
  gem "meta_request"
end

gem_group :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "webmock"
  gem "rspec-html-matchers"
end

gem_group :production do
  gem "rails_12factor"
end

gem "devise"


after_bundle do
  # Add dev:prime task

  file "lib/tasks/dev.rake", render_file("dev.rake")

  # Prevent test noise in generators

  application \
    <<-RB.gsub(/^      /, "")
      config.generators do |g|
            g.test_framework nil
            g.factory_bot false
            g.scaffold_stylesheet false
          end
    RB

  # Configure mailer in development

  environment \
    'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }',
    env: "development"


  inside "app" do
    inside "views" do
      inside "layouts" do
        insert_into_file "application.html.erb",
                         after: "    <%= csrf_meta_tags %>\n" do
          <<-HTML.gsub(/^        /, "")

            <!-- Expand the number of characters we can use in the document beyond basic ASCII 🎉 -->
            <meta charset="utf-8">

            <!-- Connect Font Awesome CSS -->
            <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.1.0/css/all.css">

            <!-- Connect Bootstrap CSS -->
            <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css">

            <!-- Connect Bootstrap JavaScript and its dependencies -->
            <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js"></script>
            <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.bundle.min.js"></script>

            <!-- Make it responsive to small screens -->
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
          HTML
        end
      end
    end
  end

  # Remove require_tree .

  # gsub_file "app/assets/stylesheets/application.css", " *= require_tree .\n", ""
  # gsub_file "app/assets/javascripts/application.js", "//= require_tree .\n", ""

  # Better backtraces
  remove_file "bin/setup"
  file "bin/setup", render_file("setup")

  run "chmod 755 bin/setup"

  remove_file "db/seeds.rb"
  file "db/seeds.rb", render_file("seeds.rb")


  file "config/initializers/nicer_errors.rb", render_file("nicer_errors.rb")

  remove_file "app/helpers/application_helper.rb"
  file "app/helpers/application_helper.rb", render_file("application_helper.rb")
  
  # remove_file "config/database.yml"
  # file "config/database.yml", render_file("database.yml")

  # gsub_file "config/database.yml", "APP_NAME", @app_name.downcase

  # Install annotate

  generate "annotate:install"

  # Set up rspec and capybara

  generate "rspec:install"

  # remove_file ".rspec"
  # file ".rspec", render_file(".rspec")

  inside "spec" do
    insert_into_file "rails_helper.rb",
                     after: "require 'rspec/rails'\n" do
      <<-RUBY.gsub(/^        /, "")
        require "capybara/rails"
        require "capybara/rspec"
      RUBY
    end
  end

  rails_command "db:create"

  file "lib/tasks/lti.rake", render_file("lti.rake")
  puts "\n== Generating resources =="
  rails_command "lti:setup"

  rails_command "db:migrate"

  git :init
  git add: "-A"
  git commit: '-m "Init"'
end
