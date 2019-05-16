# Helper methods to copy in files
# ===============================

ENV = :prod
# ENV = :dev

def path_to_file(filename)
  if ENV == :prod
    "https://raw.githubusercontent.com/firstdraft/appdev_template/master/#{filename}"
  else
    File.join(File.expand_path(File.dirname(__FILE__)), "files", filename)
  end
end

def path_to_blob(filename)
  "https://raw.githubusercontent.com/firstdraft/appdev_template/master/files/#{filename}"
end

def render_file(filename)
  if ENV == :prod
    require "open-uri"

    begin
      open(path_to_file(filename)).read
    rescue
      open(path_to_blob(filename)).read
    end
  else
    IO.read(path_to_file(filename))
  end
end

# skip_active_admin = false
# skip_devise = false
skip_active_admin = yes?("Skip ActiveAdmin?")
skip_devise = yes?("Skip Devise?")

# Remove default sqlite3 version
# =================
gsub_file "Gemfile", /^gem\s+["']sqlite3["'].*$/,''

# Add standard gems
# =================

gem "pg"

gem_group :development, :test do
  gem "awesome_print"
  gem "dotenv-rails"
  gem "pry-rails"
  gem "table_print"
end

gem_group :development do
  gem "annotate"
  gem "better_errors"
  gem "binding_of_caller"
  gem "dev_toolbar", github: "firstdraft/dev_toolbar"
  gem "draft_generators", github: "firstdraft/draft_generators"
  gem "letter_opener"
  gem "meta_request"
end

gem_group :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "webmock"
  gem 'rspec-html-matchers'
end

gem_group :production do
  gem "rails_12factor"
end

gem "devise" unless skip_devise
gem "activeadmin" unless skip_active_admin
# gem "bootstrap-sass"
# gem "jquery-rails"
# gem "font-awesome-sass", "~> 4.7.0"

# Use WEBrick

# gsub_file "Gemfile",
#   /gem 'puma'/,
#   "# gem 'puma'"

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
    "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }",
    env: "development"


  # Add dev toolbar to application layout

  inside "app" do
    inside "views" do
      inside "layouts" do
        insert_into_file "application.html.erb", before: "  </body>" do
          <<-RB.gsub(/^        /, "")

            <%= dev_tools if Rails.env.development? %>
          RB
        end
      end
    end
  end

  # TODO: Add a prompt about whether to include BS and/or FA
  # TODO: Update for BS4 beta

  # remove_file "app/assets/stylesheets/application.css"
  # file "app/assets/stylesheets/application.scss",
  #   render_file("application.scss")
  #
  # bootstrap_variables_url = "https://raw.githubusercontent.com/twbs/bootstrap-sass/master/templates/project/_bootstrap-variables.sass"
  # file "app/assets/stylesheets/_bootstrap-variables.sass",
  #   open(bootstrap_variables_url).read
  #
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

  gsub_file "app/assets/stylesheets/application.css", " *= require_tree .\n", ""
  gsub_file "app/assets/javascripts/application.js", "//= require_tree .\n", ""

  # Better backtraces

  file "config/initializers/nicer_errors.rb", render_file("nicer_errors.rb")

  inside "config" do
    inside "initializers" do
      append_file "backtrace_silencers.rb" do
        <<-RUBY.gsub(/^          /, "")

          Rails.backtrace_cleaner.add_silencer { |line| line =~ /lib|gems/ }

        RUBY
      end
    end
  end

  unless skip_active_admin
    # Set up Active Admin

    generate "active_admin:install"

    gsub_file "db/seeds.rb",
      /AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password')/,
      "AdminUser.create(email: \"admin@example.com\", password: \"password\", password_confirmation: \"password\")"

    rails_command "db:migrate"
    rails_command "db:seed"

    inside "config" do
      inside "initializers" do
        insert_into_file "active_admin.rb",
          after: "ActiveAdmin.setup do |config|\n" do
          <<-RUBY.gsub(/^      /, "")
            # If you are using Devise's before_action :authenticate_user!
            #   in your ApplicationController, then uncomment the following:

            # config.skip_before_action :authenticate_user!

          RUBY
        end

        gsub_file "active_admin.rb",
          "  # config.comments_menu = false\n",
          "  config.comments_menu = false\n"

        gsub_file "active_admin.rb",
          "  # config.comments_registration_name = 'AdminComment'\n",
          "  config.comments_registration_name = 'AdminComment'\n"
      end
    end
  end

  # Install annotate

  generate "annotate:install"

  # Set up rspec and capybara

  generate "rspec:install"

  remove_file ".rspec"
  file ".rspec", render_file(".rspec")

  inside "spec" do
    insert_into_file "rails_helper.rb",
      after: "require 'rspec/rails'\n" do
      <<-RUBY.gsub(/^        /, "")
        require "capybara/rails"
        require "capybara/rspec"
      RUBY
    end
  end

  # Turn off CSRF protection

  gsub_file "app/controllers/application_controller.rb",
    /class ApplicationController < ActionController::Base/,
    "class ApplicationController < ActionController::Base\n" +
    "\t# protect_from_forgery with: :exception\n" +
    "\tskip_before_action :verify_authenticity_token, raise: false"

  rails_command "db:migrate"

  git :init
  git add: "-A"
  git commit: "-m \"Init\""

end
