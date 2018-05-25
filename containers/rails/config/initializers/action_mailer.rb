# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => ENV["SMTP_HOST"] || "localhost",
  :user_name => ENV["SMTP_USERNAME"],
  :password => ENV["SMTP_PASSWORD"],
  :port => ENV["SMTP_PORT"] || 587,
  :domain => ENV["SMTP_DOMAIN"] || "localhost",
  :enable_starttls_auto => true,
  :authentication => :login
}