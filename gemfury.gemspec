Gem::Specification.new do |s|
  s.name              = "gemfury"
  s.version           = "0.1.1"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Client library and command-line tool to manage your gems on Gemfury"
  s.homepage          = "http://gemfury.com"
  s.email             = "mrykov@gmail.com"
  s.authors           = [ "Michael Rykov" ]
  s.has_rdoc          = false

  s.executables       = %w(gemfury fury)
  s.files             = %w(README) +
                        Dir.glob("bin/**/*") +
                        Dir.glob("lib/**/*")

  s.add_dependency    "highline", "~> 1.6.0"
  s.add_dependency    "thor", "~> 0.14.5"
  s.add_dependency    "launchy", "~> 0.4.0"
  s.add_dependency    "multi_json", "~> 1.0.2"
  s.add_dependency    "faraday", "~> 0.6.1"
  s.add_dependency    "faraday_middleware", "~> 0.6.3"

  s.description = <<DESCRIPTION
Client library and command-line tool to manage your gems on http://gemfury.com
DESCRIPTION

  s.post_install_message =<<POSTINSTALL
************************************************************************

  Upload your first gem to start using Gemfury:
  fury push my-gem-1.0.gem

  Follow @gemfury on Twitter for announcements, updates, and news.
  https://twitter.com/gemfury

************************************************************************
POSTINSTALL
end
